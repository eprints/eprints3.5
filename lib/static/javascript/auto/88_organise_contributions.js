document.addEventListener("DOMContentLoaded", (event) => {
	let contrib_content = document.querySelector('#c_contributions_content')
	if( contrib_content !== null )
	{
		// Create a button for controlling simple/advanced contributors view
        let toggle_button = document.createElement("button");
        toggle_button.setAttribute("type", "button");
		toggle_button.appendChild(document.createTextNode("Switch to Advanced View"))
		toggle_button.setAttribute("class", "btn btn-primary btn-sm m-3")
        toggle_button.setAttribute("id", "contributor_viewmode_button")                
        
        contrib_content.before(toggle_button)

        toggle_button.addEventListener('click', () => {
            switchContribView(!(toggle_button.getAttribute("data-viewmode") == "simple"))
		})

        switchContribView(true);
	}
});


// Used to switch between simple and advanced view for the contributor field.
const switchContribView = (enable_simple_view) => {
    // Update the table
    ['2', '3', '6'].forEach((n) => {
            let elems = document.querySelectorAll("#c_contributions_ajax_content_target .d-table-row .d-table-cell:nth-child(" + n + ")")
            elems.forEach((elem) => {
                    if ( enable_simple_view )
                    {
                            elem.classList.add("d-none");
                    }
                    else
                    {
                            elem.classList.remove("d-none");
                    }
            })
    })

    // Update the switcher button
    let button = document.getElementById("contributor_viewmode_button");
    let button_label = button.firstChild;

    button.setAttribute("data-viewmode", enable_simple_view ? "simple" : "advanced");
    
    // New phrase for the button, "switch to advanced..."
    let phrase_id = 'eprint_fieldname_contributions_complexity_button_';
    phrase_id += enable_simple_view ? "advanced" : "simple";

    let phrases = { [phrase_id] : {} };
    eprints.currentRepository().phrase(
        phrases,
        function (phrase) {
            button_label.textContent=phrase[phrase_id];
        }
    );
}