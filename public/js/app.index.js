window.onload = function () {
    const progressComp = document.querySelector('.mdc-linear-progress');
    const progress = new mdc.linearProgress.MDCLinearProgress(progressComp);
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
                    let iconCell = document.createElement("TD");
                    let icon = document.createElement("I");
                    if(member.is_staff) {
                        icon.setAttribute("class", "material-icons member-table-icon member-table-icon-staff");
                    } else {
                        icon.setAttribute("class", "material-icons member-table-icon");
                    }
                    icon.appendChild(document.createTextNode("person"));
                    iconCell.addEventListener("click", evt => {
                        document.location = "/profile/" + member.member_id
                    });
                    iconCell.appendChild(icon);
                    row.appendChild(iconCell);
                    let lastnameCell = document.createElement("TD");
                    lastnameCell.appendChild(document.createTextNode(member.lastname));
                    row.appendChild(lastnameCell);
                    let firstnameCell = document.createElement("TD");
                    firstnameCell.appendChild(document.createTextNode(member.firstname));
                    row.appendChild(firstnameCell);
                    let birthdateCell = document.createElement("TD");
                    birthdateCell.appendChild(document.createTextNode(member.birthdate));
                    row.appendChild(birthdateCell);
                    let telCell = document.createElement("TD");
                    let telList = document.createElement("UL");
                    telList.setAttribute("class", "members-table-link-list");
                    member.tel.forEach (tel => {
                        let telItem = document.createElement("LI");
                        let telLink = document.createElement("A");
                        telLink.setAttribute("href", "tel:" + tel);
                        telLink.appendChild(document.createTextNode(tel));
                        telItem.appendChild(telLink);
                        telList.appendChild(telItem);
                    })
                    telCell.appendChild(telList);
                    row.appendChild(telCell);
                    let emailCell = document.createElement("TD");
                    let emailList = document.createElement("UL");
                    emailList.setAttribute("class", "members-table-link-list");
                    member.email.forEach (email => {
                        let emailItem = document.createElement("LI");
                        let emailLink = document.createElement("A");
                        emailLink.setAttribute("href", "mailto:" + email);
                        emailLink.appendChild(document.createTextNode(email));
                        emailItem.appendChild(emailLink);
                        emailList.appendChild(emailItem);
                    })
                    emailCell.appendChild(emailList);
                    row.appendChild(emailCell);
                    table.appendChild(row);
                    progress.close()
                })
            } else {
                //TODO show error stuff
            }
        })
    })
    const fab = document.querySelector('#ejmadb-fab');
    const createGroup = document.querySelector('#ejmadb-create-group');
    const addPerson = document.querySelector('#ejmadb-add-person');
    fab.addEventListener('click', evt => {
        if(createGroup.hasAttribute("disabled")) {
            createGroup.removeAttribute("disabled");
            fab.setAttribute("data-active", true)
        } else {
            createGroup.setAttribute("disabled", "disabled");
            fab.removeAttribute("data-active")
        }
        if(addPerson.hasAttribute("disabled")) {
            addPerson.removeAttribute("disabled");
        } else {
            addPerson.setAttribute("disabled", "disabled");
        }
    });
}
