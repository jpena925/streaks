export default {
	mounted() {
		const tooltipText = this.el.dataset.tooltipText;
		if (!tooltipText) return;

		const tooltip = document.createElement("div");
		tooltip.className =
			"fixed pointer-events-none opacity-0 transition-opacity duration-150 z-[9999]";
		tooltip.innerHTML = `
      <div class="bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 text-xs font-semibold px-2.5 py-1.5 rounded shadow-xl whitespace-nowrap">
        ${tooltipText}
      </div>
      <div class="absolute top-full left-1/2 -translate-x-1/2 -mt-px">
        <div class="border-4 border-transparent border-t-gray-900 dark:border-t-gray-100"></div>
      </div>
    `;
		document.body.appendChild(tooltip);
		this.tooltip = tooltip;

		// Show tooltip on hover
		this.el.addEventListener("mouseenter", () => {
			const rect = this.el.getBoundingClientRect();
			const tooltipRect = tooltip.getBoundingClientRect();

			// Position above the element, centered
			tooltip.style.left = `${
				rect.left + rect.width / 2 - tooltipRect.width / 2
			}px`;
			tooltip.style.top = `${rect.top - tooltipRect.height - 8}px`;

			tooltip.classList.remove("opacity-0");
			tooltip.classList.add("opacity-100");
		});

		this.el.addEventListener("mouseleave", () => {
			tooltip.classList.remove("opacity-100");
			tooltip.classList.add("opacity-0");
		});
	},

	destroyed() {
		if (this.tooltip) {
			this.tooltip.remove();
		}
	},
};
