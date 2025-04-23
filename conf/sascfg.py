SAS_config_names = ['ssh']

# Insert your configuration details here!
my_ssh_path = '' # Path to your ssh executable
my_sas_host = '' # Your SSH connection target

ssh = {
    'saspath': '/sashome/SASFoundation/9.4/bin/sas_u8', # You may have to edit this depending on your SAS installation
    'ssh': my_ssh_path,
    'host': my_sas_host,
    'results': 'TEXT'
}