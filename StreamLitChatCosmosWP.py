from openai import AzureOpenAI
import streamlit as st
from streamlit_chat import message
import pandas as pd
import numpy as np
import json 
#Cosmos DB imports
from azure.cosmos import CosmosClient
from azure.cosmos.aio import CosmosClient as CosmosAsyncClient
from azure.cosmos import PartitionKey, exceptions

import configparser; config = configparser.RawConfigParser()
config.read('keys//keys.ini')

cosmos_uri = config['keys']['COSMOSDB_ENDPOINT']
cosmos_key = config['keys']['AzureCosmoDBcdbralvecKey']
CONTAINER_NAME = "WP-vector-nosql-cont"
DATABASE_NAME = "WP-vector-nosql-db-DiskANN"

OPENAI_API_ENDPOINT = "https://swedenopenairal.openai.azure.com/"
OPENAI_API_VERSION = "2024-02-01"
OPENAI_API_KEY = config['keys']['AzurekeySweden']

client = AzureOpenAI(api_key=OPENAI_API_KEY, azure_endpoint=OPENAI_API_ENDPOINT, api_version=OPENAI_API_VERSION,)

from azure.identity import DefaultAzureCredential
from azure.identity import ClientSecretCredential, DefaultAzureCredential

credential = DefaultAzureCredential()
cosmos_client = CosmosClient(cosmos_uri, credential, consistency_level="Strong")

AOAI_client = AzureOpenAI(api_key=OPENAI_API_KEY, azure_endpoint=OPENAI_API_ENDPOINT, api_version=OPENAI_API_VERSION,)

db= cosmos_client.get_database_client(DATABASE_NAME)
container = db.get_container_client(CONTAINER_NAME)

def generate_embeddings(text):
    '''
    Generate embeddings from string of text.
    This will be used to vectorize data and user input for interactions with Azure OpenAI.
    '''
    return client.embeddings.create(input=text, model="textembeddings3large").data[0].embedding

# Simple function to assist with vector search
def searchdatabase(query, num_results=10):
    query_embedding = generate_embeddings(query)
    results = container.query_items(
            query='SELECT TOP @num_results c.content, VectorDistance(c.contentVector,@embedding) AS SimilarityScore FROM c ORDER BY VectorDistance(c.contentVector,@embedding)',
            parameters=[{"name": "@embedding", "value": query_embedding},
                        {"name": "@num_results", "value": num_results}],
            enable_cross_partition_query=True,
                populate_index_metrics=True,
                populate_query_metrics=True)

    res = ""
    for result in results: 
        res = res + json.dumps(result["content"], indent=True) + "\r\n"

    costs = ("RUs: " + container.client_connection.last_response_headers['x-ms-request-charge'].replace(';','\n'))
    floatcost = float(container.client_connection.last_response_headers['x-ms-request-charge'].replace(';','\n')) * 0.000000199
    costs = costs + "\n" + "Cost £: " + str('{:f}'.format(floatcost))
    costs = costs + "\n" + container.client_connection.last_response_headers['x-ms-documentdb-query-metrics'].split(';')[0]

    rtnvar = st.text_area(label="Costs", value=costs)

    return res


st.title("💬 War and Peace Bot - search base GPT model or using pinecone search War and Peace")
if "messages" not in st.session_state:
    st.session_state["messages"] = [{"role": "assistant", "content": "How may I help you? Please start typing!"}]

for msg in st.session_state.messages:
    st.chat_message(msg["role"]).write(msg["content"])


with st.sidebar:

    slider = st.slider(
        label='Temp', min_value=.0,
        max_value=1.0, value=.0, key='my_slider')

    input_select = st.selectbox('select a model', 
                             options=('gpt4om', 'gpt4o', 'gpt4Turbo'),
                             key='model')
    
    checkbox_input = st.checkbox('Just War and Peace?', key='alicecb')

if prompt := st.chat_input():

    #Create a copy of the messages to send to the GPT model
    #so that we do not add loads of junk ot the history
    tosend = st.session_state.messages.copy()
    st.session_state.messages.append({"role": "user", "content": prompt})
    st.chat_message("user").write(prompt)
    messages = st.session_state.messages

    if checkbox_input:
        searchres = searchdatabase(prompt)#
        tosend.append({"role": "user", "content": prompt + ". Answer the question from the below book paragraphs. It is ok to ask for clarification. Don't make anything up but try and answer the questions. I will tip you $100 if you give a good answer. Put an emoji at the end: \r\nContext:\r\n" + searchres})
    else:
        tosend.append({"role": "user", "content": prompt})

    import time
    times = time.time()

    response = client.chat.completions.create(model=input_select,
                                            messages=tosend,
                                            temperature=slider,)
   
    timee = time.time()

    msg = response.choices[0].message
    st.session_state.messages.append({"role": "user", "content": msg.content})
    st.chat_message("assistant").write(msg.content)
    #Update textcost with the response from the GPT model

    printtext = "Time: " + str(timee - times) + " seconds"
    printtext = printtext + "\n" + "Usage: " + str(response.usage)
    printtext = printtext + "\n" + "Cost: " + str(response.usage.total_tokens * 0.0000011535)

    rtnvar = st.text_area("Costs", printtext)

    
with st.sidebar:
    
    df = pd.DataFrame(st.session_state.messages)
    "Memory"
    df

    if checkbox_input:
        "Search Index Data"
        if 'searchres' in locals():
            searchres
