import os
import pandas as pd


# load all sheets from the excel file as a dict
df_dict = pd.read_excel('data/Review_Historic_Air_Photos.xlsx', sheet_name=None)

# remove blanks from 'publications'
blank_pubs = df_dict['publications']['Human Key'] == ' ,  ()'
df_dict['publications'].drop(df_dict['publications'][blank_pubs].index, inplace=True)

# remove blank rows from the datasets table
blank_data = df_dict['datasets']['Key'].isna()
df_dict['datasets'].drop(df_dict['datasets'][blank_data].index, inplace=True)

# extract the publication key from the geographic and scientific tables
df_dict['geographic']['Pub Key'] = df_dict['geographic']['Publication Key'].str.extract(r'\(([^()]{8})\)')
df_dict['scientific']['Pub Key'] = df_dict['scientific']['Publication Key'].str.extract(r'\(([^()]{8})\)')

# first, remove all the blank rows
for sheet in df_dict.keys():
    df_dict[sheet].dropna(how='all', inplace=True)

    # delete the git blame column
    if 'git blame' in df_dict[sheet].columns:
        del df_dict[sheet]['git blame']

    # delete the publication key from each of the tables
    if 'Publication Key' in df_dict[sheet].columns:
        del df_dict[sheet]['Publication Key']

# drop the helper columns from the publications table
df_dict['publications'].drop(['interesting?', '.not_relevant', 'geographic', 'scientific',
                              'dataset', 'processing', 'outputs', 'accuracy'],
                             axis=1, inplace=True)

# drop the .relevant column from the geographic table
df_dict['geographic'].drop(['.relevant'], axis=1, inplace=True)

# drop the helper columns from the datasets table
df_dict['datasets'].drop(['processing', 'outputs', 'accuracy'], axis=1, inplace=True)

# add a pub key column to the datasets table
df_dict['datasets']['Pub Key'] = df_dict['datasets']['Key'].str.split('.', expand=True)[0]

# join the dataset columns:
datasets_df = df_dict['datasets'].set_index('Key')\
    .join(df_dict['processing'].set_index('Key'), rsuffix='_proc')\
    .join(df_dict['accuracy'].set_index('Key'), rsuffix='_acc')\
    .join(df_dict['outputs'].set_index('Key'), rsuffix='_out')

# join the publications, geographic, and scientific tables to the datasets_df
pubs_df = df_dict['publications'].set_index('Key')\
    .join(df_dict['geographic'].set_index('Pub Key'), rsuffix='_geog')\
    .join(df_dict['scientific'].set_index('Pub Key'), rsuffix='_sci')\
    .join(datasets_df.set_index('Pub Key'), rsuffix='_data')

# save to a csv file
pubs_df.to_csv(os.path.join('data', 'Review_Historic_Air_Photos.csv'), index_label='Key')
