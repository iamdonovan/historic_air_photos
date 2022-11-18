import pandas as pd
import sqlite3


def _coords(row):
    return (tuple(row[['lon_min', 'lat_min']].values),
            tuple(row[['lon_max', 'lat_min']].values),
            tuple(row[['lon_max', 'lat_max']].values),
            tuple(row[['lon_min', 'lat_max']].values))


df_dict = pd.read_excel('Review_ Historic Air Photos.xlsx', sheet_name=None)

# dict_keys(['publications', 'geographic', 'scientific', 'datasets',
# 'processing', 'accuracy', 'outputs'])

pubs = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='publications')
geog = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='geographic')
sci  = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='scientific')
data = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='datasets')
proc = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='processing')
acc = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='accuracy')
outs = pd.read_excel('data/Review_ Historic Air Photos.xlsx', sheet_name='outputs')


db_conn = sqlite3.connect('data/test.db')
db_conn.enable_load_extension(True)
db_conn.load_extension('mod_spatialite')

# create publications table
db_conn.execute(
    """
    CREATE TABLE publications (
        id TEXT NOT NULL,
        Author TEXT NOT NULL,
        Year INTEGER NOT NULL,
        Title TEXT NOT NULL,
        PubTitle TEXT,
        DOI TEXT,
        Relevant INTEGER,
        PRIMARY KEY(id)
        );
    """
)

# create geographic table - TODO: figure out the geometries!
db_conn.execute(
    """
    CREATE TABLE geographic (
        GeoID TEXT NOT NULL,
        Geom BLOB,
        Notes TEXT,
        PubID TEXT NOT NULL,
        PRIMARY KEY(GeoID),
        FOREIGN KEY(PubID) REFERENCES publications(id)
        );
    """
)

db_conn.execute('SELECT InitSpatialMetaData(1);')
db_conn.execute("SELECT AddGeometryColumn('geographic', 'Geometry', 4326, 'MULTIPOLYGON', 'XY');")
db_conn.execute("SELECT CreateSpatialIndex('geographic', 'Geometry');")

# create scientific table
c.execute(
    """
    CREATE TABLE scientific (
        PubID TEXT NOT NULL,
        DataType TEXT NOT NULL,
        StudyType TEXT NOT NULL,
        Category TEXT NOT NULL,
        Relevant INTEGER,
        Description TEXT,
        Notes TEXT,
        FOREIGN KEY(PubID) REFERENCES publications(id)
        );
    """
)

# create datasets table
c.execute(
    """
    CREATE TABLE datasets (
        PubID TEXT NOT NULL,
        DataID TEXT NOT NULL,
        Type TEXT NOT NULL,
        Location TEXT,
        Free TEXT,
        ArchiveName TEXT,
        StartYear INTEGER NOT NULL,
        EndYear INTEGER NOT NULL,
        Calibration TEXT,
        FlightHeight INTEGER,
        HeightRef TEXT,
        GSD REAL,
        Scale TEXT,
        ScanRes REAL,
        ScanUnit TEXT,
        NumImgs INTEGER,
        Notes TEXT,
        PRIMARY KEY(DataID),
        FOREIGN KEY(PubID) REFERENCES publications(id)
        );
    """
)

# create processing table
c.execute(
    """
    CREATE TABLE processing (
        PubID TEXT NOT NULL,
        DataID TEXT NOT NULL,
        Method TEXT NOT NULL,
        Software TEXT,
        Version TEXT,
        GCPs TEXT,
        Fiducial TEXT,
        PreProc TEXT,
        PreProcNote TEXT,
        WorkNote TEXT,
        Related TEXT,
        PRIMARY KEY(DataID),
        FOREIGN KEY(PubID) REFERENCES publications(id)
        );
    """
)

# create accuracy table
c.execute(
    """
    CREATE TABLE accuracy (
        PubID TEXT NOT NULL,
        DataID TEXT NOT NULL,
        SourceXY TEXT,
        SourceZ TEXT,
        AccuracyXY REAL,
        AccuracyZ REAL,
        NumGCPs INTEGER,
        XYRes REAL,
        ZRes REAL,
        Comparison TEXT,
        CompAccXY REAL,
        CompAccZ REAL,
        CompResXY REAL,
        CompResZ REAL,
        Metric TEXT,
        PostProc TEXT,
        Notes TEXT,        
        PRIMARY KEY(DataID),
        FOREIGN KEY(PubID) REFERENCES publications(id)
        );
    """
)

# create outputs table
c.execute(
    """
    CREATE TABLE outputs (
        PubID TEXT NOT NULL,
        DataID TEXT NOT NULL,
        Output TEXT NOT NULL,
        OrthoRes REAL,
        DEMRes REAL,
        Note TEXT,
        PRIMARY KEY(DataID),
        FOREIGN KEY(PubID) REFERENCES publications(id)
        );
    """
)

pubs.rename(mapper={'Key': 'id', 'Publication Title': 'PubTitle', '.not_relevant': 'Relevant'}, axis='columns', inplace=True)
pubs[['id', 'Author', 'Year', 'Title', 'PubTitle', 'DOI', 'Relevant']].to_sql('publications', db_conn, if_exists='append', index=False)

geog['GeoID'] = geog.index
geog['PubID'] = geog['Publication Key'].str.extract(r'\((.*?)\)')

geog.dropna(subset=['lat_min', 'lat_max', 'lon_min', 'lon_max'], inplace=True)
geog['Geom'] = [Polygon(_coords(row)).wkb for ii, row in geog.iterrows()]
# geog['Geometry'] = [Polygon(_coords(row)).wkb for ii, row in geog.iterrows()]
geog[['GeoID', 'Geom', 'Notes', 'PubID']].to_sql('geographic', db_conn, if_exists='append', index=False)

db_conn.execute("UPDATE geographic SET Geometry = CastToMultiPolygon(ST_GeomFromWKB(Geom, 4326));")
db_conn.execute("ALTER TABLE geographic DROP COLUMN IF EXISTS Geom;")

sci['PubID'] = sci['Publication Key'].str.extract(r'\((.*?)\)')
sci.rename(mapper={'Data Type': 'DataType', 'Type of Study': 'StudyType'}, axis='columns', inplace=True)
sci[['PubID', 'DataType', 'StudyType', 'Category', 'Relevant', 'Description', 'Notes']].to_sql('scientific', db_conn, if_exists='append', index=False)

data[['PubID', 'Num']] = outs['Key'].str.split('.', expand=True)
data.rename(mapper={'Key': 'DataID', 'Archive Location': 'Location', 'Freely Available?': 'Free', 
                    'Archive Name': 'ArchiveName', 'Acquisition Start Year': 'StartYear',
                    'Acquisition End Year': 'EndYear', 'Camera calib?': 'Calibration',
                    'Flight Height [m]': 'FlightHeight', 'Height reference': 'HeightRef',
                    'GSD [m]': 'GSD', 'Scanner resolution': 'ScanRes', 'Scanner resolution units': 'ScanUnit',
                    'No. Images': 'NumImgs'}, axis='columns', inplace=True)
data[['PubID', 'DataID', 'Type', 'Location', 'Free', 'ArchiveName', 'StartYear', 'EndYear', 
      'Calibration', 'FlightHeight', 'HeightRef', 'GSD', 'Scale', 'ScanRes', 'ScanUnit', 
      'NumImgs', 'Notes']].to_sql('datasets', db_conn, if_exists='append', index=False)

proc[['PubID', 'Num']] = outs['Key'].str.split('.', expand=True)
proc.rename(mapper={'Key': 'DataID', 'Fidcial Marks': 'Fiducial', 'Pre-processing': 'PreProc',
                    'Pre-processing Note': 'PreProcNote', 'Workflow Note': 'WorkNote',
                    'Related paper': 'Related'}, axis='columns', inplace=True)
proc[['PubID', 'DataID', 'Method', 'Software', 'Version', 'GCPs', 'Fiducial', 
      'PreProc', 'PreProcNote', 'WorkNote', 'Related']].to_sql('processing', db_conn, if_exists='append', index=False)

acc[['PubID', 'Num']] = outs['Key'].str.split('.', expand=True)
acc.rename(mapper={'Key': 'DataID', 'Ground control source XY': 'SourceXY', 'Ground control source Z': 'SourceZ',
                   'Ground control accuracy [m] XY': 'AccuracyXY', 'Ground control accuracy [m] Z': 'AccuracyZ',
                   'No. GCPs': 'NumGCPs', 'Residuals to GCPs [m] XY': 'XYRes', 'Residuals to GCPs [m] Z': 'ZRes', 
                   'Comparison data': 'Comparison', 'Accuracy comparison data [m] XY': 'CompAccXY', 'Accuracy comparison data [m] Z': 'CompAccZ',
                   'Residuals to comparison [m] XY': 'CompResXY', 'Residuals to comparison [m] Z': 'CompResZ', 
                   'comparison metric': 'Metric', 'Post-Processing': 'PostProc'}, axis='columns', inplace=True)
acc[['PubID', 'DataID', 'SourceXY', 'SourceZ', 'AccuracyXY', 'AccuracyZ', 'NumGCPs',
     'XYRes', 'ZRes', 'Comparison', 'CompAccXY', 'CompAccZ', 'Metric', 'PostProc', 'Notes']].to_sql('accuracy', db_conn, if_exists='append', index=False)

outs[['PubID', 'Num']] = outs['Key'].str.split('.', expand=True)
outs.rename(mapper={'Key': 'DataID', 'DEM resolution [m]': 'DEMRes', 'Orthophoto resolution [m]': 'OrthoRes', 'note': 'Note'}, axis='columns', inplace=True)
outs[['PubID', 'DataID', 'Output', 'OrthoRes', 'DEMRes', 'Note']].to_sql('outputs', db_conn, if_exists='append', index=False)


