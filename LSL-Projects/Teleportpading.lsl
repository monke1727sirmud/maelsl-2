// Enhanced Teleporter Pad Script with Networking and Auto-Sync
string allowedNotecard = "AllowedUsers";
string bannedNotecard = "BannedUsers";
list allowedUsers;
list bannedUsers;

default
{
    state_entry()
    {
        llSay(0, "Teleporter is ready. Please step on the pad.");
        // Load allowed users
        llGetNotecardLine(allowedNotecard, 0);
        // Load banned users
        llGetNotecardLine(bannedNotecard, 0);
        // Start listening on a specific channel for sync messages
        llListen(12345, "", NULL_KEY, ""); // Change 12345 to your desired channel
    }

    // Handle notecard reading
    dataserver(key query_id, string data)
    {
        if (data != "")
        {
            if (query_id == llGetNotecardLine(allowedNotecard, 0))
            {
                allowedUsers += data; // Add to allowed users list
                llGetNotecardLine(allowedNotecard, llGetListLength(allowedUsers)); // Get next line
            }
            else if (query_id == llGetNotecardLine(bannedNotecard, 0))
            {
                bannedUsers += data; // Add to banned users list
                llGetNotecardLine(bannedNotecard, llGetListLength(bannedUsers)); // Get next line
            }
        }
        else
        {
            // Finished reading notecard
            if (query_id == llGetNotecardLine(allowedNotecard, 0))
            {
                llSay(0, "Finished loading allowed users.");
            }
            else if (query_id == llGetNotecardLine(bannedNotecard, 0))
            {
                llSay(0, "Finished loading banned users.");
            }
        }
    }

    touch_start(integer total_number)
    {
        key toucher = llDetectedKey(0);
        string toucherName = llKey2Name(toucher);

        // Check if the user is banned
        if (llListFindList(bannedUsers, [toucherName]) != -1)
        {
            llSay(0, "You are banned from using this teleporter.");
            return;
        }

        // Check if the user is allowed
        if (llListFindList(allowedUsers, [toucherName]) != -1)
        {
            // Notify all users about the teleportation
            llSay(0, toucherName + " is being teleported.");
            // Teleport the user to the destination (example coordinates)
            vector destination = <128.0, 128.0, 30.0>; // Change to your desired destination
            rotation rot = ZERO_ROTATION; // No specific rotation
            vector lookAt = ZERO_VECTOR; // No specific look direction
            llTeleportAgent(key agent, vector destination, rotation rot, vector lookAt);
            llSay(0, "Teleporting " + toucherName + " to the destination.");
        }
        else
        {
            llSay(0, "You are not allowed to use this teleporter.");
        }
    }

    // Networking functionality
    on_rez(integer start_param)
    {
        llResetScript(); // Reset the script to load notecards again
    }

    // Auto-sync function
    listen(integer channel, string name, key id, string message)
    {
        if (message == "sync")
        {
            // Sync the allowed and banned users lists
            llSay(0, "Syncing user lists...");
            // Here you can implement logic to sync with other teleporters if needed
        }
    }
}