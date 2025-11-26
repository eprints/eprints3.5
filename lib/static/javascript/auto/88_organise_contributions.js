document.addEventListener("DOMContentLoaded", function () {
  const selects = document.querySelectorAll("div[id^='c_contributions_contributions_cell_1_'] select[id^='c_contributions_contributions_'][id$='_type']");

  selects.forEach((select) => {
    const options = Array.from(select.options);
    let optgroup;
    options.forEach((option, index) => {
      if (index === 1) {
        optgroup = document.createElement("optgroup");
        optgroup.label = "Common";
        select.insertBefore(optgroup, option);
      }
      if (index === 3) {
        optgroup = document.createElement("optgroup");
        optgroup.label = "People";
        select.insertBefore(optgroup, option);
      }
      if (index === 7) {
        optgroup = document.createElement("optgroup");
        optgroup.label = "Associations";
        select.insertBefore(optgroup, option);
      }
      if (index === 11) {
        optgroup = document.createElement("optgroup");
        optgroup.label = "Other";
        select.insertBefore(optgroup, option);
      }

      if (optgroup) {
        optgroup.appendChild(option);
      }
    });
  });
});

document.addEventListener("DOMContentLoaded", (event) => {
	let contrib_content = document.querySelector('#c_contributions_content')
	if( contrib_content !== null )
	{
		let toggle = document.createElement("div")
		toggle.appendChild(document.createTextNode("View Toggle"))
		toggle.setAttribute("class", "btn btn-primary btn-sm m-3")
		contrib_content.before(toggle)

		toggle.addEventListener('click', () => {
			toggleContrib()
		})
		toggleContrib()
	}
});

const toggleContrib = () => {
                let children = ['2', '3', '6']
                children.forEach((n) => {
                        let elems = document.querySelectorAll("#c_contributions_ajax_content_target .d-table-row .d-table-cell:nth-child(" + n + ")")
                        elems.forEach((elem) => {
                                if( elem.classList.contains("d-none") )
                                {
                                        elem.classList.remove("d-none")
                                }
                                else
                                {
                                        elem.classList.add("d-none")
                                }
                        })
                })
}

/*

#c_contributions_ajax_content_target .d-table-row .d-table-cell:nth-child(2),
#c_contributions_ajax_content_target .d-table-row .d-table-cell:nth-child(3),
#c_contributions_ajax_content_target .d-table-row .d-table-cell:nth-child(6)
{
  display: none !important;
}

*/
