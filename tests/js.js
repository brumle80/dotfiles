/**
 * Test JavaScript file
 */

const ns = {};

/**
 * onClick
 *
 * @param {Event} e
 */
ns._onClick = function onClick(e) {
  return false;
};

/**
 * something
 *
 * @type {Boolean}
 */
ns.SOMETHING = true;

/**
 * retSomething
 *
 * @return {Boolean}
 */
ns.retSomething = function () {
  return ns.SOMETHING;
};

window.addEventListener('click', ns._onClick);
window.testvalue = true;

// ===========================================================================
// Start typing a word should complete from all sources

;;;
;;;

// ===========================================================================
// Adding an s after here should trigger deoplete-ternjs
window.te

// ===========================================================================
// Adding . after here should trigger deoplete-ternjs
window
ns

// ===========================================================================
// Adding apostrophe after here should trigger jspc#omni
window.addEventListener(

