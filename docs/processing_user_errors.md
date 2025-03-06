# Project Import Errors

1. Retrieve the errors from the import and save them to a file
1. Run the following in the rails console

```
errors = File.open("user-errors.txt").read
csv_data = UserErrorParser.csv_users(errors)
file = File.open("new_users.csv","w")
file.write(csv_data)
file.close
```

1. Pass the csv file on to Matt to update user spreadsheet
