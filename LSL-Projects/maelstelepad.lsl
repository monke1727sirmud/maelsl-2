// Constants
integer SYNC_CHANNEL = -123456;  // Shared channel for synchronization
string NOTECARD_NAME = "AccessControl";  // Name of the notecard
integer line_index = 0;  // Track current line in the notecard
list ALLOWED_USERS;  // List of allowed users
list DISALLOWED_USERS;  // List of disallowed users
list TELEPORT_LOCATIONS;  // Names of teleport locations
list TELEPORT_COORDS;  // Coordinates of teleport locations

// Function to read the next line of the notecard
read_next_line() {
    llGetNotecardLine(NOTECARD_NAME, line_index);
    line_index++;
}

// Function to parse a line from the notecard
process_line(string line) {
    if (llGetSubString(line, 0, 6) == "ALLOWED") {
        ALLOWED_USERS += [llGetSubString(line, 8, -1)];
    } else if (llGetSubString(line, 0, 9) == "DISALLOWED") {
        DISALLOWED_USERS += [llGetSubString(line, 11, -1)];
    } else if (llGetSubString(line, 0, 9) == "LOCATION:") {
        list parts = llParseString2List(llGetSubString(line, 10, -1), ["|"], []);
        if (llGetListLength(parts) == 2) {
            TELEPORT_LOCATIONS += [llList2String(parts, 0)];
            TELEPORT_COORDS += [(vector)llList2String(parts, 1)];
        }
    }
}

// Function to broadcast data to other pads
broadcast_data() {
    string data = llList2CSV(ALLOWED_USERS) + ";" +
                  llList2CSV(DISALLOWED_USERS) + ";" +
                  llList2CSV(TELEPORT_LOCATIONS) + ";" +
                  llList2CSV(TELEPORT_COORDS);
    llRegionSay(SYNC_CHANNEL, "DATA:" + data);
}

// Function to parse and synchronize data from another pad
synchronize_data(string data) {
    list parts = llParseString2List(data, [";"], []);
    if (llGetListLength(parts) == 4) {
        ALLOWED_USERS = llParseString2List(llList2String(parts, 0), [","], []);
        DISALLOWED_USERS = llParseString2List(llList2String(parts, 1), [","], []);
        TELEPORT_LOCATIONS = llParseString2List(llList2String(parts, 2), [","], []);
        TELEPORT_COORDS = llParseString2List(llList2String(parts, 3), [","], []);
        llOwnerSay("Data synchronized with network.");
    } else {
        llOwnerSay("Error: Invalid data received for synchronization.");
    }
}

// Function to show the menu to a user
show_menu(key user) {
    list buttons = TELEPORT_LOCATIONS;
    llDialog(user, "Choose a location to teleport:", buttons, -55555);
}

// Function to teleport a user
teleport_user(key user, integer location_index) {
    vector destination = llList2Vector(TELEPORT_COORDS, location_index);
    llSay(0, "Teleporting to " + llList2String(TELEPORT_LOCATIONS, location_index) + "...");
    llSetRegionPos(destination);
}

// State entry for initialization
default {
    state_entry() {
        // Initialize lists and start reading the notecard
        ALLOWED_USERS = [];
        DISALLOWED_USERS = [];
        TELEPORT_LOCATIONS = [];
        TELEPORT_COORDS = [];
        line_index = 0;
        llListen(SYNC_CHANNEL, "", NULL_KEY, "");  // Listen for network updates
        read_next_line();  // Start reading the notecard
    }

    dataserver(key query_id, string data) {
        if (data == EOF) {
            llOwnerSay("Finished reading notecard. Broadcasting data...");
            broadcast_data();  // Broadcast the data to the network
            return;
        }

        process_line(data);  // Parse the line from the notecard
        read_next_line();  // Continue reading
    }

    touch_start(integer num_detected) {
        key user = llDetectedKey(0);
        string user_name = llDetectedName(0);

        // Check if the user is allowed
        if (llListFindList(ALLOWED_USERS, [user_name]) != -1) {
            show_menu(user);  // Show the menu if allowed
        } else if (llListFindList(DISALLOWED_USERS, [user_name]) != -1) {
            llSay(0, "Sorry, you are not allowed to use this teleport pad.");
        } else {
            llSay(0, "You are not on the access list for this teleport pad.");
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == SYNC_CHANNEL) {
            if (llGetSubString(message, 0, 4) == "DATA:") {
                synchronize_data(llGetSubString(message, 5, -1));
            }
        }
    }

    listen_response(integer channel, string name, key id, string message) {
        // Handle the teleport location selected from the menu
        integer location_index = llListFindList(TELEPORT_LOCATIONS, [message]);
        if (location_index != -1) {
            teleport_user(id, location_index);
        } else {
            llSay(0, "Invalid location selected.");
        }
    }
}
