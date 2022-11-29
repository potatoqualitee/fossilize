# Fossilize - Mastodon account backup tool

This Action will help you backup Mastodon account items to CSV files, including:

* Follows
* Mutes
* Account blocks
* Lists
* Bookmarks
* Domain blocks
* Followers
* Posts

The export is performed using the Mastodon API and an Access Token.

Note that Followers and Posts cannot be imported using Mastodon's import web interface. Also, posts are exported in JSON format because they are more complex.

## Documentation

Here's how you'd export your follows, lists, blocks, mutes, domain_blocks, bookmarks, followers, and posts if your account is on the dataplatform.social Mastodon instance. This will export the files to `./backups` then attach a zip of the `./backups` as an artifact to the workflow run.

```yaml
- name: Backup account to files
  uses: potatoqualitee/fossilize@v1
    with:
        server: dataplatform.social
    env:
        ACCESS_TOKEN: "${{ secrets.ACCESS_TOKEN }}"
```

Note that Mastodon limits API calls to 300 per 5 minutes, which averages 1 second so each call will have a delay of one second, so that's why there seems to be a slight delay.

# Usage

## Pre-requisites

### Get a Mastodon Bearer Token

A Mastodon token is required for this Action to work. Fortuantely, it's very easy to get one.

Go to your Mastodon profile/client/webpage and click Preferences -> Development -> New Application -> Application name: Whatever you like, I named mine Imports -> Limit Permissions (optional) -> Submit

> **Note**
>
> If you limit your permissions too much when you create the app, you may need to recreate it. I was too strict with my permissions and it _looked_ like I could edit them but the edit is like a secondary scope

Click new application link -> Your access token

### Add GitHub Secrets

Once you have your authentication information, you will need to them to your [repository secrets](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces#adding-secrets-for-a-repository).

I named my secret `TOKEN`. You can modify the names, though you must ensure that your environmental variables are named appropriately, as seen in the sample code.

### Create workflows

Finally, create a workflow `.yml` file in your repositories `.github/workflows` directory. An [example workflow](#example-workflow) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

## Inputs

* `server` - Your Mastodon server. If you are dbatools@dataplatform.social, this would be dataplatform.social.
* `path` - The path to the directory that will hold the CSV files, defaults to `./backups`. This Action will create the directory if it does not exist.
* `type` - Which items to backup. Options include: follows, lists, blocks, mutes, domain_blocks, bookmarks, followers, posts and all. Defaults to all.
* `auto-artifact` - Attach the csv files as an artifact to this workflow. Default is true.
* `artifact-name` - The name of the artifact. Default is mastodon-backup.
* `verbose` - Show verbose output. Defaults to true.

## Outputs

* `csv-path` - The backup directory file path

### Example workflows

Use the `Fossilize` action to backup your account to CSV each night at midnight and attach the zip as an artifact

```yaml
name: Backup Mastodon Account
on:
  workflow_dispatch:
  schedule:
    - cron: "0 0 * * *"
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v3

      - name: Backup Mastodon Account
        uses: ./
        id: backup
        with:
          server: dataplatform.social
        env:
          ACCESS_TOKEN: "${{ secrets.ACCESS_TOKEN }}"
```

### Details

Here's some extra examples for the inputs.

| Input | Example | Another Example | And Another
| --- | --- | --- | --- |
| server | dataplatform.social | dbatools@dataplatform.social | https://dataplatform.social
| path | /tmp/backups | ./backups

### Want to run this locally?

Just add your `$env:ACCESS_TOKEN` environmental variables to your `$profile` and reload, clone the repo, change directories, modify this command and run.

```powershell
./main.ps1 -Server yourinstance.tld -Path C:\temp\backups
```

## Contributing
Pull requests are welcome!

## TODO
You tell me! I'm open to suggestions.

## License
The scripts and documentation in this project are released under the [MIT License](LICENSE)
