// Teleport Pad Script with Allowed and Banned Users from Notecards
// This script allows specified users to teleport while banning others.

list allowedUsers; // List of allowed users
list bannedUsers;  // List of banned users
vector TARGET_LOCATION; // Target location for teleportation
string TARGET_REGION = "TargetRegion"; // Name of the target region

default
{
    state_entry()
    {
        llSay(0, "Teleport Pad Active. Touch to teleport.");
        // Start reading allowed users from notecard
        llGetNotecardLine("AllowedUsers", 0);
        // Start reading banned users from notecard
        llGetNotecardLine("BannedUsers", 0);
        // Start reading target location from notecard
        llGetNotecardLine("TargetLocation", 0);
    }

    // Handle notecard reading
    dataserver(key query_id, string data)
    {
        if (data != "")
        {
            // Check if we are reading allowed users
            if (llSubStringIndex(query_id, "AllowedUsers") != -1)
            {
                allowedUsers += [data]; // Add to allowed users list
                llGetNotecardLine("AllowedUsers", llGetListLength(allowedUsers)); // Read next line
            }
            // Check if we are reading banned users
            else if (llSubStringIndex(query_id, "BannedUsers") != -1)
            {
                bannedUsers += [data]; // Add to banned users list
                llGetNotecardLine("BannedUsers", llGetListLength(bannedUsers)); // Read next line
            }
            // Check if we are reading target location
            else if (llSubStringIndex(query_id, "TargetLocation") != -1)
            {
                // Parse the string to create a vector
                list coords = llParseString2List(data, [",", " "], []);
                if (llGetListLength(coords) == 3)
                {
                    // Cast each component to float and create the vector
                    TARGET_LOCATION = <(float)llList2String(coords, 0), (float)llList2String(coords, 1), (float)llList2String(coords, 2)>;
                }
                llGetNotecardLine("TargetLocation", llGetListLength(coords)); // Read next line
            }
        }
        else
        {
            llSay(0, "Finished reading notecards.");
        }
    }

    touch_start(integer total_number)
    {
        key toucher = llDetectedKey(0);
        string toucherName = llKey2Name(toucher);

        // Check if the user is banned
        if (llListFindList(bannedUsers, [toucherName]) != -1)
        {
            llSay(0, "You are banned from using this teleport pad.");
            return; // Exit if the user is banned
        }

        // Check if the user is allowed
        if (llListFindList(allowedUsers, [toucherName]) != -1)
        {
            llSay(0, "Teleporting " + toucherName + " to " + TARGET_REGION + " at " + (string)TARGET_LOCATION);
            osTeleportAgent(toucher, TARGET_REGION, TARGET_LOCATION); // Teleport the agent
        }
        else
        {
            llSay(0, "You are not authorized to use this teleport pad.");
        }
    }

    on_rez(integer start_param)
    {
        llResetScript(); // Reset the script on rez
    }
}