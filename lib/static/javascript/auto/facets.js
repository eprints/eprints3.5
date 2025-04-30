// Facets

window.addEventListener("load", function () {

    for (const facet of this.document.querySelectorAll("[data-ep-facet]")) {

        const facetId = `facet_${facet.getAttribute("data-ep-facet")}`;
        const values = facet.querySelectorAll("[data-ep-facet-value]");
        const showMore = facet.querySelector(".ep_facet_show_more");

        for (const value of values) {

            const valueId = value.getAttribute("data-ep-facet-value");

            function updateFacet() {

                const params = new URLSearchParams(document.location.search);

                let values = [];

                if (params.has(facetId)) {
                    values = params.get(facetId).split("|");
                }

                const valueIndex = values.indexOf(valueId);

                if (valueIndex === -1) {
                    values.push(valueId);
                } else {
                    values.splice(valueIndex, 1);
                }

                if (values.length > 0) {
                    params.set(facetId, values.join("|"));
                } else {
                    params.delete(facetId);
                }

                params.delete("search_offset");

                const newLocation = new URL(document.location);

                newLocation.search = params.toString();

                window.location = newLocation;
            }

            value.querySelector("input[type=checkbox]").addEventListener("click", updateFacet);
            value.querySelector("a.ep_facet_label").addEventListener("click", updateFacet);
        }

        if (showMore !== null) {

            showMore.addEventListener("click", function () {

                for (const value of values) {
                    value.style.display = "flex";
                }

                showMore.style.display = "none";
            })
        }
    }
});
