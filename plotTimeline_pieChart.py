# import packages
import pandas as pd
from pathlib import Path
import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# ..........................
# Set directory and filename
file_folder = 'M:/privat/02_Paper/Paper_HistoricalImages/Data_GoogleSheet'
excelFileName = 'Review_HistoricAirPhotos_download8May2022.xlsx'
outputPlot_path = Path(r"M:/privat/02_Paper/Paper_HistoricalImages/Figure/PythonPlot")

# =====================================================================================================================
#                                                   PLOT THE TIMELINE
# =====================================================================================================================
# ....................................................
# Import excel file as pandas dataframe using datetime
df_dataset = pd.read_excel(os.path.join(file_folder, excelFileName), sheet_name='datasets',
                           parse_dates=['Acquisition Start Year', 'Acquisition End Year'])
df_dataset.head()

# ...................
# prepare the dataset
df_dataset_select = df_dataset[['Key', 'Dataset Number', 'Type',
                                'Acquisition Start Year', 'Acquisition End Year']].copy()

# rename 'Acquisition Start Year' and 'Acquisition End Year' using shorter name
df_dataset_select.rename(columns={'Acquisition Start Year': 'start_date', 'Acquisition End Year': 'end_date'},
                         inplace=True)

# extract the key: extract the string before the dot and save it in a new column in the dataframe
unique_key_value = df_dataset_select.Key.str[0:-1].str.split('.', expand=True)
df_dataset_select['unique_key'] = unique_key_value[0]

# Sort the dataframe by dates and Type
df_aerial_satellite_sortDate = df_dataset_select.sort_values(['Type', 'start_date'], ascending=[True, True])

# create list of unique key of aerial and satellite
listKey_sorted_all = df_aerial_satellite_sortDate['unique_key'].unique()

# add a new column ('uniquekey_ID') with a consecutive number for unique keys
df_aerial_satellite_sortDate['uniquekey_ID'] = 1
n = 1
for i in listKey_sorted_all:
    for j in df_aerial_satellite_sortDate.index:
        if df_aerial_satellite_sortDate.loc[j, 'unique_key'] == i:
            df_aerial_satellite_sortDate.loc[j, 'uniquekey_ID'] = n
    n = n + 1

# df_aerial_satellite_sortDate['uniquekey_ID'][df_aerial_satellite_sortDate['Type'] == 'Aerial'].max()    # 113
y_max = df_aerial_satellite_sortDate['uniquekey_ID'][df_aerial_satellite_sortDate['Type'] == 'Satellite'].max()    # 150

# .................
# PLOT THE TIMELINE

# Define the color and legend labels
lineCol_aer = '#fbbab6'
lineCol_satel = '#7fdfe1'
labels_legend = ['Aerial', 'Satellite']

fig = plt.figure(figsize=(11, 5))
sns.set(font_scale=1.3, style="white"), sns.set_style('ticks')  # white style with tick marks
for n in range(1, y_max):
    selection = df_aerial_satellite_sortDate.loc[(df_aerial_satellite_sortDate['uniquekey_ID'] == n) & (df_aerial_satellite_sortDate['Type'] == 'Aerial')]
    #print(selection)
    plt.plot(selection['start_date'], selection['uniquekey_ID'], color=lineCol_aer, linewidth=2, marker='o', alpha=0.6)

    selection = df_aerial_satellite_sortDate.loc[(df_aerial_satellite_sortDate['uniquekey_ID'] == n) & (df_aerial_satellite_sortDate['Type'] == 'Satellite')]
    plt.plot(selection['start_date'], selection['uniquekey_ID'], color=lineCol_satel, linewidth=2, marker='o', alpha=0.6)

labels_legend = ['Aerial', 'Satellite']
plt.legend(labels_legend,loc='upper left')
plt.ylabel('Number of studies', fontsize=18)
plt.xlabel('Acquisition year', weight='bold', fontsize=18)
plt.title("Timeline of historical images for each study", fontsize=20)
plt.show()

plt.savefig(outputPlot_path/'timeLine_test.png', dpi=300, bbox_inches='tight')


# =====================================================================================================================
#                                      PLOT THE PIE CHART OF APPLICATIONS
# =====================================================================================================================

# .....................................
# Import excel file as pandas dataframe
df_scientific = pd.read_excel(os.path.join(file_folder, excelFileName), sheet_name='scientific')

# ....................
# prepare the dataset
# select columns; use double [[ so that the output is a dataframe
df_scientific_slct = df_scientific[['Data Type', 'Type of Study', 'Category', 'Relevant']].copy()

# select only row with "relevant" == "yes"
df_scientific_slct_rel = df_scientific_slct.loc[df_scientific_slct['Relevant'] == 'yes']
df_scientific_slct_rel.head()

# grouped by the applications and count the data for applications
df_scientific_slct_rel_cnt = df_scientific_slct_rel.groupby(['Category']).size().reset_index(name='count')

# sort count values from the largest to the smallest
df_scientific_slct_rel_cnt_sort = df_scientific_slct_rel_cnt.copy()
df_scientific_slct_rel_cnt_sort.sort_values(by=['count'], inplace=True, ascending=False)

# ..........................
# PLOT PIE CHART APPLICATION

# prepare pie chart data
labels = df_scientific_slct_rel_cnt_sort['Category']
count = df_scientific_slct_rel_cnt_sort['count']

#colors
# https://aesalazar.com/blog/professional-color-combinations-for-dashboards-or-mobile-bi-applications
# https://www.pinterest.com/pin/91831279880141327/
# https://chartio.com/learn/charts/how-to-choose-colors-data-visualization/
colours = {'Archeology': '#ffe001',
           'Ecology': '#8dd7bf',
           'Forestry': '#019477',
           'Geomorphology': '#ffa23a',
           'Glaciology': '#66b3ff',
           'Hydrology': '#bbdaf6',
           'Landuse/Landcover': '#9c58a1',
           'Methodology': '#6c88c4',
           'Urban Change': '#c3d2cc',
           'Volcanology': '#ff9999'}
colors = [colours[key] for key in labels]

# "explode" the slice glacialogy (no 1)
explode = (0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0)

# https://medium.com/@kvnamipara/a-better-visualisation-of-pie-charts-by-matplotlib-935b7667d77f
fig = plt.gcf()
plt.pie(count, colors=colors, labels=labels, autopct='%1.0f%%', startangle=2, pctdistance=0.85, explode=explode)
# donut chart
centre_circle = plt.Circle((0,0), 0.70, fc='white')  # draw a circle centered at (0,0)
fig.gca().add_artist(centre_circle)
# add text inside the plot
plt.text(-0.6, -0.1, 'Applications', fontsize=30)
# Equal aspect ratio ensures that pie is drawn as a circle
plt.axis('equal')
plt.tight_layout()
plt.show()

plt.savefig(outputPlot_path/'PieChart_applications.png', dpi=300, bbox_inches='tight')

# =====================================================================================================================
#                                         PLOT THE PIE CHART OF OUTPUT
# =====================================================================================================================

# .....................................
# Import excel file as pandas dataframe
df_output = pd.read_excel(os.path.join(file_folder, excelFileName), sheet_name='outputs')

# ....................
# prepare the dataset
df_output_slct = df_output[['Key', 'Output']].copy()

# extract the unique key: extract the string before the dot and save it in a new column in the dataframe
unique_key_value = df_output_slct.Key.str[0:-1].str.split('.', expand=True)
df_output_slct['unique_key'] = unique_key_value[0]

# Sort the dataframe by Output
df_output_slct_sort = df_output_slct.sort_values(['Output'], ascending=[True])    # dataframe

# drop empty (i.e. nan) rows from a Pandas dataframe
df_output_slct_sort.dropna(subset=["Output"], inplace=True)   # dataframe

# drop duplicated unique_key
df_output_slct_sort_drop = df_output_slct_sort.copy()
df_output_slct_sort_drop.drop_duplicates(subset ="unique_key", keep='first', inplace=True)

# count the rows for each output and create a series of count and label
labels_out = df_output_slct_sort['Output'].unique()
count_pieChart = pd.Series([sum(df_output_slct_sort_drop['Output']==labels_out[0]),
                            sum(df_output_slct_sort_drop['Output']==labels_out[1]),
                            sum(df_output_slct_sort_drop['Output']==labels_out[2])])
# count_pieChart.sum() # check

labels_out_pieChart = pd.Series([labels_out[0],
                                 labels_out[1],
                                 labels_out[2]])
# .....................
# PLOT PIE CHART OUTPUT
colors_out2 = {'2D (georeferenced)': '#0671b7',
           '2D (orthophoto)': '#67a3d9',
           '3D (point cloud/DEM)': '#c8e7f5'}
colors = [colors_out2[key] for key in labels_out_pieChart]

explode = (0, 0, 0)   #no explode
fig = plt.gcf()
plt.pie(count_pieChart, colors=colors, labels=labels_out_pieChart, autopct='%1.0f%%', startangle=90, pctdistance=0.85, explode=explode)
# donut chart
centre_circle = plt.Circle((0,0), 0.70, fc='white')  # draw a circle centered at (0,0)
fig.gca().add_artist(centre_circle)
# add text inside the plot
plt.text(-0.3, -0.1, 'Output', fontsize=30)
# Equal aspect ratio ensures that pie is drawn as a circle
plt.axis('equal')
plt.tight_layout()
plt.show()

plt.savefig(outputPlot_path/'PieChart_output.png', dpi=300, bbox_inches='tight')