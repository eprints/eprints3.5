document.addEventListener("DOMContentLoaded", (event) => {
	let contrib_content = document.querySelector('#c_contributions_content')
	if( contrib_content !== null )
	{
		let toggle = document.createElement("div")
                let toggle_text = document.createTextNode("Advanced View")//default text, will be overriden as soon as the phrase loads
		toggle.appendChild(toggle_text)
		toggle.setAttribute("class", "btn btn-primary btn-sm m-3")
		contrib_content.before(toggle)

		toggle.addEventListener('click', () => {
			toggleContrib(toggle_text)
		})
		toggleContrib(toggle_text)
	}
});

const toggleContrib = (toggle_text_node) => {
                let switch_to_advanced = true;
                let children = ['2', '3', '6'];
                children.forEach((n) => {
                        let elems = document.querySelectorAll("#c_contributions_ajax_content_target .d-table-row .d-table-cell:nth-child(" + n + ")")
                        elems.forEach((elem) => {
                                if( elem.classList.contains("d-none") )
                                {
                                        
                                        switch_to_advanced = true;
                                        elem.classList.remove("d-none");
                                }
                                else
                                {
                                        // switching to simple view
                                        switch_to_advanced = false;

                                        elem.classList.add("d-none");
                                }
                        })
                })

                if(switch_to_advanced){
                        eprints.currentRepository().phrase(
                        { 'eprint_fieldname_contributions_complexity_button_simple' : {} },
                        function (phrase) {
                                toggle_text_node.textContent=phrase['eprint_fieldname_contributions_complexity_button_simple'];
                        });
                }else{
                        eprints.currentRepository().phrase(
                        { 'eprint_fieldname_contributions_complexity_button_advanced' : {} },
                        function (phrase) {
                                toggle_text_node.textContent=phrase['eprint_fieldname_contributions_complexity_button_advanced'];
                        });
                }
                
}
