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
