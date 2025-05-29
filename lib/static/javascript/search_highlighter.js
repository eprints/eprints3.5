// Highlight the given elements with the given regex
function highlightRegExp(elements, regex) {
	for (const element of elements) {
		let text = '';
		let blocks = [];

		// Loop through all the children and collect the text and marks into one string ('text') noting
		//  where they came from in 'blocks' ({start, end, node}).
		for (const child of element.childNodes) {
			if (child.nodeType === Node.TEXT_NODE && child.textContent.trim() !== '') {
				blocks.push({start: text.length, end: (text += child.textContent).length, node: child});
			} else if (child.nodeType === Node.ELEMENT_NODE && child.nodeName === 'MARK') {
				if (blocks.length > 0 && blocks[blocks.length - 1].node.nodeType === Node.ELEMENT_NODE) {
					text += 1;
				}
				blocks.push({start: text.length, end: (text += child.textContent).length, node: child});
			} else {
				// If there is something else in between the text elements (like a span) we want to apply
				//  highlighting separately on either side of the other element.
				applyHighlighting(element, text, blocks);
				text = '';
				blocks = [];
			}
		}
		applyHighlighting(element, text, blocks);
	}

	function applyHighlighting(parentElement, text, blocks) {
		const matches = findMatches(text, blocks);

		for (const match of matches) {
			const mark = document.createElement('mark');
			mark.innerText = text.substring(match.start, match.end);

			const startBlock = blocks[match.startBlock];
			const endBlock = blocks[match.endBlock];

			const leading = startBlock.node.textContent.substring(0, match.start - startBlock.start);
			const trailing = endBlock.node.textContent.substring(match.end - endBlock.start);

			// If we have trailing text then we replace the endNode with it and insert the mark before it.
			// Otherwise we replace the endNode with the mark directly.
			if (trailing !== '') {
				let trailingNode = endBlock.node;
				if (endBlock.node.nodeType === Node.TEXT_NODE) {
					endBlock.node.textContent = trailing;
				} else {
					trailingNode = document.createTextNode(trailing);
					parentElement.replaceChild(trailingNode, endBlock.node);
				}
				parentElement.insertBefore(mark, trailingNode);
			} else {
				parentElement.replaceChild(mark, endBlock.node);
			}
			// If there is text before the mark we have to insert another text node for it.
			if (leading !== '') {
				parentElement.insertBefore(document.createTextNode(leading), mark);
			}
			// We then need to delete any nodes between startBlock and endBlock except endBlock.
			for (let i = match.startBlock; i < match.endBlock; i++) {
				parentElement.removeChild(blocks[i].node);
			}

			// We have trimmed 'leading' and 'mark' off endBlock.node so we need to move its start.
			endBlock.start = match.end;
		}
	}

	// Find all times the regex matches 'text'.
	// This will return a list of {start, end, startBlock, endBlock} objects.
	function findMatches(text, blocks) {
		let matches = [];
		let match = regex.exec(text);
		while (match !== null && match[0] !== '') {
			let start = match.index;
			let end = start + match[0].length;

			// Get the range of blocks that start..end exist in.
			// For example  searching for 3-9 in [0-2][3-5][5-7][8-13][13-20] returns [1, 3]
			outer: for (var startBlock = 0; startBlock < blocks.length; startBlock++) {
				if (blocks[startBlock].end > start) {
					for (var endBlock = startBlock; endBlock < blocks.length; endBlock++) {
						if (blocks[endBlock].end >= end) {
							break outer;
						}
					}
				}
			}

			// If we start or end with a mark node then we stretch this match to fill that so that we don't nest marks.
			if (blocks[startBlock].node.nodeType === Node.ELEMENT_NODE) {
				start = blocks[startBlock].start;
			}
			if (blocks[endBlock].node.nodeType === Node.ELEMENT_NODE) {
				end = blocks[endBlock].end;
			}
			matches.push({start: start, end: end, startBlock: startBlock, endBlock: endBlock});
			match = regex.exec(text);
		}
		return matches;
	}
}

var previousElement = null;
// Run the 'highlight' function over each of the 'ep_search_result' elements
// This will run the function over any new elements as we infinite scroll.
function highlightSearch(highlight) {
	applyHighlighting();
	document.addEventListener('ep_infiniteScrollEvent', applyHighlighting);

	function applyHighlighting() {
		if (previousElement === null) {
			var thisElement = document.getElementsByClassName('ep_search_result')[0];
		} else {
			var thisElement = previousElement.nextElementSibling;
		}
		if (!thisElement) return;

		highlight(thisElement);
		previousElement = thisElement;
		applyHighlighting();
	}
}
