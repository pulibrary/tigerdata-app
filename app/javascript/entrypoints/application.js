// import 'bootstrap/js/src/alert'  
// import 'bootstrap/js/src/button'  
// import 'bootstrap/js/src/carousel'  
import 'bootstrap/js/src/collapse'  
import 'bootstrap/js/src/dropdown'  
// import 'bootstrap/js/src/modal'  
// import 'bootstrap/js/src/popover'  
import 'bootstrap/js/src/scrollspy'  
// import 'bootstrap/js/src/tab'  
// import 'bootstrap/js/src/toast'  
// import 'bootstrap/js/src/tooltip' 

import * as bootstrap from 'bootstrap';
window.bootstrap = bootstrap;

// initialize the page
window.addEventListener('load', (event) => {
    initPage();
});
window.addEventListener('turbo:render', (event) => {
    initPage();
});

window.test_jquery = function() {
    $('#test-jquery').html('jQuery works!')
}