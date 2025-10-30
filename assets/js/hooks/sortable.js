/**
 * Sortable Hook for drag-and-drop reordering
 * 
 * Usage:
 * <div phx-hook="Sortable" id="habits-list" data-handle=".drag-handle">
 *   <div data-id="1">...</div>
 *   <div data-id="2">...</div>
 * </div>
 */
export default {
  mounted() {
    const hook = this;
    const handleSelector = this.el.dataset.handle || ".drag-handle";
    let draggedElement = null;
    let draggedOver = null;

    // Get all sortable items
    const getItems = () => {
      return Array.from(this.el.children).filter(
        (el) => el.hasAttribute("data-id")
      );
    };

    // Add draggable attribute to items
    const items = getItems();
    items.forEach((item) => {
      item.setAttribute("draggable", "true");

      // Find the drag handle within the item
      const handle = item.querySelector(handleSelector);
      if (handle) {
        // Make the handle visually draggable
        handle.style.cursor = "grab";

        // Only allow dragging when initiated from the handle
        item.addEventListener("mousedown", (e) => {
          if (handle.contains(e.target)) {
            item.setAttribute("draggable", "true");
          } else {
            item.setAttribute("draggable", "false");
          }
        });
      }

      // Drag start
      item.addEventListener("dragstart", (e) => {
        if (item.getAttribute("draggable") !== "true") {
          e.preventDefault();
          return;
        }

        draggedElement = item;
        item.style.opacity = "0.5";
        e.dataTransfer.effectAllowed = "move";
        e.dataTransfer.setData("text/html", item.innerHTML);

        // Change cursor on handle
        if (handle) {
          handle.style.cursor = "grabbing";
        }
      });

      // Drag end
      item.addEventListener("dragend", (e) => {
        item.style.opacity = "1";
        draggedElement = null;
        draggedOver = null;

        // Reset cursor on handle
        if (handle) {
          handle.style.cursor = "grab";
        }

        // Remove all drag-over classes
        getItems().forEach((item) => {
          item.classList.remove("drag-over");
        });

        // Send new order to server
        const newOrder = getItems().map((el) => el.dataset.id);
        hook.pushEvent("reorder", { ids: newOrder });
      });

      // Drag over
      item.addEventListener("dragover", (e) => {
        if (draggedElement === null) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = "move";

        // Remove previous drag-over styling
        if (draggedOver && draggedOver !== item) {
          draggedOver.classList.remove("drag-over");
        }

        draggedOver = item;
        item.classList.add("drag-over");

        // Reorder in DOM immediately for smooth visual feedback
        if (draggedElement !== item) {
          const allItems = getItems();
          const draggedIndex = allItems.indexOf(draggedElement);
          const targetIndex = allItems.indexOf(item);

          if (draggedIndex < targetIndex) {
            item.parentNode.insertBefore(draggedElement, item.nextSibling);
          } else {
            item.parentNode.insertBefore(draggedElement, item);
          }
        }
      });

      // Drag enter
      item.addEventListener("dragenter", (e) => {
        if (draggedElement === null) return;
        e.preventDefault();
      });

      // Drag leave
      item.addEventListener("dragleave", (e) => {
        if (item === draggedOver) {
          item.classList.remove("drag-over");
        }
      });

      // Drop
      item.addEventListener("drop", (e) => {
        e.stopPropagation();
        e.preventDefault();
        return false;
      });
    });
  },
};

