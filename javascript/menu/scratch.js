var get_ancestors = function(container,subtype, ele){
  var excepts = [];
  var element = ele;
  while (element.parentElement.tagName != container){
    if (element.classList.contains(subtype))
      excepts.push(element);
    element = element.parentElement;
  }
  return excepts
}  

var apply_fun = function(dom, func){
  func()
}


function notUnder(ancestors, ele) {
  // this === null
  return 'ele is not an element under ancestors';
}

var hide_submenus = function(except){
    var submenus = document.getElementsByClassName('submenu');
    var ancestors = get_ancestors(except);
     
    submenus.filter(notUnder.bind(null, ancestors)).forEach(hideSubmenu);
  
  };

  
  
// This is a recommended way :)
function getAllAncestorsFor(elements) {
  return elements.map(get_ancestors.bind(null, container, subtype));
}

/*  
return elements.map(function(ele){
  return get_ancestors(ele,container,subtype);
}
)*/
