# update-ip-cf
This script/daemon will help you to update the IP in DNS record in Cloudflare using yor API credentials.

### Installation

1. Clone the repository to you server `git clone https://github.com/B1gG/update-ip-cf.git`.

2. Create the file **update-ip-cf.conf** from **update-ip-cf.conf.example**, with `cp update-ip-cf.conf.example update-ip-cf.conf` and update it as follows:

   - AUTH_KEY="**<your_key_here>**"

     Update with the value generated in the  [Get your API token](https://dash.cloudflare.com/profile/api-tokens). Remeber this need to be able to **Edit zone DNS**.

   - AUTH_EMAIL="**<your_email>**"
     Update with the email you use to login in Clodflare.

   - ZONE_ID="**<the_zone_ID_as_in_your_cf_dashboard>**"
     Use the value **Zone ID** provided in the **Overview** page in the **Dashboard**, **API** section (currently bottom right of the page)

   - RECORD_ID="**<id_field_associated_to_the_record>**"

     They way I found this value was making a API call to list all the DNS Records in the zone, following the example in the [documentation](https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records). e.g.

     ```bash
     curl -X GET "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records" \
          -H "X-Auth-Email: <AUTH_EMAIL>" \
          -H "X-Auth-Key: <AUTH_KEY>" \
          -H "Content-Type: application/json"
     ```

     Check the JSON output for the field ID related to the record you want update. (Use the [CodeBeautify JSON viewer](https://codebeautify.org/jsonviewer) to make it easier).

   - TYPE="**A**"

     This is the type of record you want to update, in theory IP only is used in an type "A" (Address) record, but maybe you want to adapt this script to change value in a CNAME record. For now keep it as is with "A".

   - NAME="**<name_in_the_record_you_want_to_update>**"

     Name of the record to update is requiered by the API, it will be the value in name in the JSON, the same that appear in the dashboard. (e.g. dynamic)

   - LAST_IP=**0.0.0.0**

     Last known IP, 0.0.0.0 or blank. this value will be updated every time there is a change.

3. Make sure the file **update-ip-cf.sh** is executable, with `chmod +x update-ip-cf.sh`

4. Now test the script with `./update-ip-cf.sh`. You can use the script as is in a cron job, but if you just want to forget about this and make it run as part of **systemd**  follow the new steps.

5. Create a directory in **/etc** named as  **update-ip-cf** with `sudo mkdir /etc/update-ip-cf`

6. Move the **.sh** and **.conf** files there with `sudo mv update-ip-cf.sh update-ip-cf.config -t /etc/update-ip-cf`

7. Move the **.service** and **.timer** files to the **systemd/system** folder, as:

   - In **Debian** (and alike) it is */lib/systemd/system/*, use `sudo mv update-ip-cf.service update-ip-cf.timer -t /lib/systemd/system/`

   - In **RedHat** (and alike) it is */etc/systemd/system/*, use `sudo mv update-ip-cf.service update-ip-cf.timer -t /etc/systemd/system/`

     > NOTE: I may be wrong on RedHat location as I am not an RH user, but you got the idea, wherever the other **.service** and **.timer** are (the actual file not the symlinks)

8. Check the service status with `sudo systemctl status update-ip-cf.service`

   It should say something like:

   ```bash
   update-ip-cf.service - Update the external IP of the server in Cloudflare via API calls
      Loaded: loaded (/lib/systemd/system/update-ip-cf.service; static; vendor preset: enabled)
      Active: inactive (dead)
   ```

9. Start the service, it will run once, with `sudo systemctl start update-ip-cf.service`

   > You can check more details about each time it runs with `sudo journalctl --unit update-ip-cf.service`

10. Enable the schedule timer for the task with sudo systemctl enable update-ip-cf.timer

11. Start the timer with sudo systemctl start update-ip-cf.timer

   > You can check all the timers in the system with `sudo systemctl list-timers`

### Other Considerations

#### Make it to run twice a day

For this edit the file .timer and change the line **OnCalendar=hourly** with **OnCalendar=\*-\*-\* 00,12:00:00**

> ```bash
> [Unit]
> Description=Run update-ip-cf hourly
> 
> [Install]
> WantedBy=timers.target
> 
> [Timer]
> **OnCalendar=\*-\*-\* 00,12:00:00**
> Persistent=true
> ```
