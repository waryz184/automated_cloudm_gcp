#!/bin/bash

# Prompt the user for input
echo "Enter the project name:"
read project_name

# Generate random number
random_number=$((1000 + RANDOM % 9000))

# Combine variables to keep gcloud command clean
combined_name=${project_name}${random_number}

# Create the project using the user input and a random number to prevent conflict
gcloud projects create $combined_name

# Select the previously created project
gcloud config set project $combined_name

# Prompt the user for service account name with validation loop
while true; do
    echo "Enter the service account name (6-30 characters):"
    read service_account_name

    # Check if the length is within the allowed range
    if [[ ${#service_account_name} -ge 6 && ${#service_account_name} -le 30 ]]; then
        break
    else
        echo "Invalid service account name length. It must be between 6 and 30 characters."
    fi
done

# Create the service account using the user input
gcloud iam service-accounts create $service_account_name

# Assign Owner role to the service account on the project
gcloud projects add-iam-policy-binding $combined_name --member="serviceAccount:${service_account_name}@${combined_name}.iam.gserviceaccount.com" --role="roles/owner"

echo "Service account '${service_account_name}' has been granted Owner role on project '${combined_name}'."

# Generate a P12 key for the service account
echo "Generating P12 key for the service account..."
gcloud iam service-accounts keys create ${service_account_name}.p12 --iam-account=${service_account_name}@${combined_name}.iam.gserviceaccount.com --key-file-type=p12

echo "P12 key saved as '${service_account_name}.p12'."
echo "Warning, the P12 key is sensitive, you must download it on your local computer."

# APIs activation
gcloud services enable admin.googleapis.com drive.googleapis.com gmail.googleapis.com calendar-json.googleapis.com people.googleapis.com tasks.googleapis.com forms.googleapis.com groupsmigration.googleapis.com

echo "All APIs is activated for your CloudM Project"

# Retrieve and display the Client ID for domain-wide delegation
client_id=$(gcloud iam service-accounts describe ${service_account_name}@${combined_name}.iam.gserviceaccount.com --format="value(oauth2ClientId)")

echo "Client ID for domain-wide delegation: $client_id"