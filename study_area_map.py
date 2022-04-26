import pandas as pd
import geopandas as gpd
from shapely.geometry.polygon import Polygon
from shapely.geometry.multipolygon import MultiPolygon
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches


def _coords(row):
    return [row[['lon_min', 'lat_min']].values, row[['lon_max', 'lat_min']].values,
            row[['lon_max', 'lat_max']].values, row[['lon_min', 'lat_max']].values]

plt.ion()

# read the geographic sheet from the excel file
df_dict = pd.read_excel('data/Review_Historic_Air_Photos.xlsx', sheet_name=['geographic', 'scientific'])

# extract the publication key from the geographic and scientific tables
for sheet in df_dict.keys():
    df_dict[sheet]['Pub Key'] = df_dict[sheet]['Publication Key'].str.extract(r'\(([^()]{8})\)')

    # drop empty rows
    df_dict[sheet].dropna(how='all', inplace=True)

    # drop the publication key
    df_dict[sheet].drop(['Publication Key'], axis=1, inplace=True)

df = df_dict['geographic'].set_index('Pub Key').join(df_dict['scientific'].set_index('Pub Key'), rsuffix='_sci')
df.dropna(subset='lat_min', inplace=True)

# add a geometry column
df['geometry'] = [_coords(row) for ii, row in df.iterrows()]
df['geometry'] = df['geometry'].apply(Polygon)

# only take the papers that are counted as "relevant"
df = df[df['Relevant'] == 'yes']

study_areas = gpd.GeoDataFrame(df[['Data Type', 'geometry']])
study_areas.set_crs(epsg=4326, inplace=True)

ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()

alpha = 0.2

study_areas[study_areas['Data Type'] == 'Satellite'].plot(ax=ax, alpha=alpha, fc='r', ec='k')
study_areas[study_areas['Data Type'] == 'Aerial'].plot(ax=ax, alpha=alpha, fc='b', ec='k')
study_areas[study_areas['Data Type'] == 'Mix'].plot(ax=ax, alpha=alpha, fc='k', ec='k')

handles = list()
for fc in ['r', 'b', 'k']:
    handles.append(mpatches.Rectangle((0, 0), 1, 1, facecolor=fc, edgecolor='k', alpha=alpha))

labels = ['Satellite', 'Aerial', 'Mix']

ax.legend(handles, labels, fontsize=14, loc='lower left', frameon=True, framealpha=1)
