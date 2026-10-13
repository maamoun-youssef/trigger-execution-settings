({
    loadApps: function(cmp) {
        console.log("-----------HELPER---------------");
        // Load all NegOptim Apps
        var action = cmp.get("c.loadApps");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var responseArray = response.getReturnValue();
                var jsonData = JSON.parse(responseArray);
                console.log("Raw Result");
                console.log(jsonData);
                cmp.set("v.apps", jsonData);
                console.log("--------------------------");
            } else if (state === "INCOMPLETE") {
                console.log("[c.loadApps] Failed to load data, Status: INCOMPLETE")
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})