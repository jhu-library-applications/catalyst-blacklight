#!/usr/bin/env python3
import json
import uuid
import os
import requests
import csv
import time

headers = {
    'Content-Type': "application/json"
}


print("*************************************")


#print(data["response"]["numFound"])
#print(data["response"]["maxScore"])

#TODO add top 5 bibs scores?

test_results = []

with open('sample.csv') as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    for row in readCSV:
        term=row[0]
        print(term)
        time.sleep(5)

        #fire solr test query
        api_url = ' http://catsolrmaster-test.library.jhu.edu:8983/solr/catalyst/select?_=1583247475700&indent=on&q='+term+'&wt=json'
        response = requests.get(api_url, headers=headers, verify=False)
        data = json.loads(response.text)

        test_result_count=data["response"]["numFound"]
        test_maxScore=data["response"]["maxScore"]

        #fire solr prod query
        api_url = ' http://catsolrmaster.library.jhu.edu:8983/solr/catalyst/select?_=1583247475700&indent=on&q='+term+'&wt=json'
        response = requests.get(api_url, headers=headers, verify=False)
        data = json.loads(response.text)

        print(data["response"])

        prod_result_count=data["response"]["numFound"]
        prod_maxScore=data["response"]["maxScore"]

        #store results
        test_results.append({"terms":term, "test-numFound":test_result_count, "test-maxScore":test_maxScore, "prod-numFound":prod_result_count, "prod-maxScore":prod_maxScore })

print(str(test_results))

with open('output.json', 'w') as outfile:
    json.dump(test_results, outfile)

# now we will open a file for writing 
csv_file = open('output.csv', 'w') 
  
# create the csv writer object 
csv_writer = csv.writer(csv_file)

count = 0
  
for result in test_results: 
    if count == 0: 
        #header = {result.keys() }
        csv_writer.writerow(result.keys()) 
        count += 1
  
    # Writing data of CSV file 
    csv_writer.writerow(result.values()) 
  
csv_file.close()  