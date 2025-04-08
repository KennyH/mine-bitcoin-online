
# GitHub Secrets

The following GitHub Actions Secrets are needed:
```
AWS_ACCOUNT_ID

DEV_NEXT_PUBLIC_NEXTAUTH_URL
DEV_NEXT_PUBLIC_COGNITO_CLIENT_ID
DEV_NEXT_PUBLIC_COGNITO_USER_POOL_ID
DEV_NEXT_PUBLIC_COGNITO_DOMAIN

PROD_NEXT_PUBLIC_NEXTAUTH_URL
PROD_NEXT_PUBLIC_COGNITO_CLIENT_ID
PROD_NEXT_PUBLIC_COGNITO_USER_POOL_ID
PROD_NEXT_PUBLIC_COGNITO_DOMAIN
```

# Other notes

- Some Terraform `variables` are hard coded within the worflow yml files. For instance, the domain names are hard-coded for the dev and prod environments...because it wasn't worth trying to figure out why terraform was holding for the values despite having defaults set.
- If the Plan and Deploy actions are canceled, it will cause a state lock on the next invocation. Clearing this automatically is something that can be done to improve these actions, but until then one will need to get the lock id and run the unlock action (or delete the item(s) in the DynamoDB table manually). 