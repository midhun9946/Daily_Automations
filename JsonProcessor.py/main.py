import os
import json
from datetime import date
##Function To create Folder structure
def createfolder(parent_dir, directory):
    path = os.path.join(parent_dir, directory)
    if not os.path.exists(path):
        os.mkdir(path)
        print("Directory '% s' created" % directory)
## Variable
today=str(date.today())
parentdirectory=r'C:\Users\itadmin\PycharmProjects\interview'
process_path=parentdirectory+'\\'+today
createfolder(parentdirectory,today)
createfolder(process_path,'proceesed')
createfolder(process_path,'unprocessed')

## JSON Read and Write block
with open('test.json','r') as myfile:
    data=myfile.read()
    obj = json.loads(data)
    for raw in obj:
        print(raw)
        if not raw['email']:
            with open(process_path+'\\unprocessed\\'+raw['call_id'], 'w') as outputFile:
                json_object = json.dumps(raw, indent=6)
                outputFile.writelines(json_object)
        else:
            with open(process_path + '\\proceesed\\' + raw['call_id'], 'w') as outputFile:
                json_object = json.dumps(raw, indent=6)
                outputFile.writelines(json_object)
