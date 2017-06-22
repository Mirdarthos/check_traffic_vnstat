# a Plugin for Icinga2 to check the traffic on a specific interface using "vnstat". #

I searched high and low for something that would monitor the traffic ratee of network interfaces. I couldn't find something. So I decided to "roll my own", so to speak. Using bash. And I've never used bash before.

I took it as a challenge, since learning bash and doing something in it is something I've been wanting to do for some time now, so this seemed like a perfect opportunity.


I present to you the fruit of my labour. No doubt there is many things that can be done differently, or even better, but this is my first bash script, so sorry if there are some unnecessary things. **Please point them out if there are.**

**This is free software with ABSOLUTELY NO WARRANTY.**

----------
## Arguments: ##
- -w: Incoming Speed Warning
- -c: Incoming speed Critical
- -W: Outgoing speed Warning
- -C: Outgoing speed Critical
- -i: Interface this should monitor
- -p: Whether the script should provide performance data or not PLEASE NOTE: The more network interfaces present, the longer the check will take if Performance Data is neccesary to be retrieved.

## Note: ##
The units you specify the warnings/critical in must be units "KiB", otherwise the script will not work correctly, and eveything would give incorrect information.

## Usage: ##
    ./check_traffic_vnstat.sh -w <incomingwarning> -W <outgoingwarning> -c <incomingcritical> -C <outgoingcritical> -i <interface> -p
## Extra Credit: ##
- Thanks to [AboutTimeIStoppedLurking](https://imgur.com/user/AboutTimeIStoppedLurking), [karmalicious79](https://imgur.com/user/karmalicious79) and [SendPotatoes ](https://imgur.com/user/SendPotatoes)on [www.imgur.com](www.imgur.com "www.imgur.com") for their helping me with this.
 
