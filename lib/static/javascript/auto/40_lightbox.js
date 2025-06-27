class Lightbox {
	imageURLs = [];

	// Set up the lightbox on any link with the class `className`
	constructor(className) {
		// We shouldn't create the lightbox elements if they already exist
		if (!document.getElementById('overlay')) {
			// Add the overlay and lightbox to the bottom of the page
			// (in such a way as to not break DOM references)
			document.querySelector('body').insertAdjacentHTML('beforeend', `
<div id="overlay" style="display: none;"></div>
<div id="lightbox" style="display: none;"><div id="outerImageContainer"><div id="imageContainer"><img id="lightboxImage" alt="Lightbox"><div id="lightboxMovie" alt="Lightbox"></div><div id="loading"><a id="loadingLink" href="#"><img src="/style/images/lightbox/loading.gif" alt="Loading"></a></div></div></div><div id="imageDataContainer"><div id="imageData"><div id="hoverNav"><a id="prevLink"></a><a id="nextLink"></a></div><div id="imageDetails"><span id="caption"></span><span id="numberDisplay"></span></div><div id="bottomNav"><a id="bottomNavClose" href="#"><img src="/style/images/lightbox/closelabel.gif" alt="Close"></a></div></div></div></div>`
			);

			// Close if the overlay, lightbox or close button is pressed.
			document.getElementById('overlay').addEventListener('click', Lightbox.close);
			document.getElementById('bottomNav').addEventListener('click', Lightbox.close);
			// We only want to close on the lightbox if the event hasn't
			// bubbled as this means we have clicked off to the side whereas if
			// it bubbles then we clicked somewhere on the image or its border.
			document.getElementById('lightbox').addEventListener('click', (ev) => {
				if (ev.srcElement === ev.currentTarget) Lightbox.close(ev);
			});
		}

		let i = 0;
		for (const element of document.getElementsByClassName(className)) {
			this.imageURLs.push(element.getAttribute('href'));

			const index = i;
			element.addEventListener('click', (ev) => {
				this.show(index);
				ev.preventDefault();
			});

			i++;
		}
	}

	// Show the lightbox for the image with index `imageIndex`
	show(imageIndex) {
		const overlay = document.getElementById('overlay');
		overlay.style.width = Math.max(document.body.scrollWidth, self.innerWidth) + 'px';
		overlay.style.height = Math.max(document.body.scrollHeight, self.innerHeight) + 'px';

		// Fade from 0.0 to 0.8 over the course of 200ms
		overlay.style.opacity = 0;
		let fadeIndex = 0;
		const intervalId = setInterval(() => {
			fadeIndex++;
			overlay.style.opacity = 0.04 * fadeIndex;
			overlay.style.display = '';
			if (fadeIndex === 20) {
				clearInterval(intervalId);
			}
		}, 10);

		// Hide the 'Prev' and 'Next' links as we don't yet handle them
		document.getElementById('prevLink').style.display = 'none';
		document.getElementById('nextLink').style.display = 'none';

		const lightbox = document.getElementById('lightbox');
		lightbox.style.top = document.documentElement.scrollTop + (window.innerHeight / 10) + 'px';
		lightbox.style.display = '';

		const loadingSpinner = document.getElementById('loading');
		const lightboxImage = document.getElementById('lightboxImage');
		loadingSpinner.style.display = '';
		lightboxImage.style.display = 'none';

		// We create the new image separately and then swap it in once it has
		// finished 'decoding' so that there are no flickers while it loads and it
		// ensures it is the correct size.
		const newImage = new Image();
		newImage.src = this.imageURLs[imageIndex];
		newImage.decode().then(() => {
			const newWidth = newImage.width + 20 + 'px';

			const outerImageContainer = document.getElementById('outerImageContainer');
			outerImageContainer.style.width = newWidth;
			outerImageContainer.style.height = newImage.height + 'px';

			document.getElementById('imageDataContainer').style.width = newWidth;

			// Duplicate the relevant attributes and then swap the elements.
			newImage.id = lightboxImage.id;
			newImage.alt = lightboxImage.alt;
			lightboxImage.replaceWith(newImage);

			lightboxImage.style.display = '';
			loadingSpinner.style.display = 'none';
		});
	}

	// Close the lightbox and fade the overlay out
	static close(ev) {
		// Fade the overlay from 0.8 to 0.0 in 200ms
		const overlay = document.getElementById('overlay');
		let fadeIndex = 0;
		const intervalId = setInterval(() => {
			fadeIndex++;
			overlay.style.opacity = 0.8 - 0.04 * fadeIndex;
			if (fadeIndex === 20) {
				overlay.style.display = 'none';
				clearInterval(intervalId);
			}
		}, 10);

		document.getElementById('lightbox').style.display = 'none';

		// This is a '#' link so if we don't prevent default it jumps to the
		// top of the page when closing.
		ev.preventDefault();
	}
}

document.addEventListener('DOMContentLoaded', () => {
	new Lightbox('lightbox');
});

