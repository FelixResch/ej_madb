window.onload = function () { 
    fetch("/api/v1/groups/" + status.group_id + "/members", {method: "GET"}).then(d => {
        d.json().then(json => {
            if(json.api.version !== "0.1.0") {
                console.warn("Invalid version in API response, might lead to unexpected results...");
                console.info("Received version was " + json.api.version + " expected 0.1.0");
            }
            if(json.success) {
                let table = document.querySelector('#members-table-body');
                json.members.forEach(member => {
                    let row = document.createElement("TR");
                    let firstnameCell = document.createElement("TD");
                    firstnameCell.appendChild(document.createTextNode(member.firstname));
                    row.appendChild(firstnameCell);
                    let lastnameCell = document.createElement("TD");
                    lastnameCell.appendChild(document.createTextNode(member.lastname));
                    row.appendChild(lastnameCell);
                    let birthdateCell = document.createElement("TD");
                    birthdateCell.appendChild(document.createTextNode(member.birthdate));
                    row.appendChild(birthdateCell);
                    let telCell = document.createElement("TD");
                    let telList = document.createElement("UL");
                    member.tel.forEach (tel => {
                        let telItem = document.createElement("LI");
                        telItem.appendChild(document.createTextNode(tel));
                        telList.appendChild(telItem);
                    })
                    telCell.appendChild(telList);
                    row.appendChild(telCell);
                    let emailCell = document.createElement("TD");
                    let emailList = document.createElement("UL");
                    member.email.forEach (email => {
                        let emailItem = document.createElement("LI");
                        emailItem.appendChild(document.createTextNode(email));
                        emailList.appendChild(emailItem);
                    })
                    emailCell.appendChild(emailList);
                    row.appendChild(emailCell);
                    table.appendChild(row);
                })
            } else {
                //TODO show error stuff
            }
        })
    })
}
