// don't pollute the global scope
(function(){
  
  // @NOTE I tested/developed with Chrome version 38
  
  // the hardcoded JSON object representing the menu data (which normally would come from some resource, ajax, system file, etc.)
  // normally we would receive a JSON string and parse it into a javascript object; this is being glossed over here...
  var the_menu = {
    items: [
      {
        name: 'Game',
        items: [
          {name: 'World of Warcraft'},
          {name: 'Diablo III'},
          {name: 'Starcraft'},
          {name: 'Hearthsone'}
        ]
      },
      { name: 'Community'},
      {
        name: 'Media',
        items: [
          {name: 'Images'},
          {name: 'Videos'}
        ]
      },
      {
        name: 'Forums',
        items: [
          {
            name: 'Gameplay',
            items: [
              {name: 'Sub entry 1'},
              {name: 'Sub entry 2'}
            ]
          },
          {
            name: 'Classes',
            items: [
              {name: 'Barbarian'},
              {name: 'Demon Hunter'},
              {name: 'Monk'},
              {name: 'Witch Doctor'},
              {name: 'Wizard'}
            ]
          },
          {
            name: 'Beta',
            items: [
              {name: 'Sub entry 1'},
              {name: 'Sub entry 2'}
            ]
          },
          {
            name: 'Support',
            items: [
              {name: 'Sub entry 1'},
              {name: 'Sub entry 2'}
            ]
          }
        ]
      },
      {
        name: 'Services',
        items: [
          {name: 'Sub entry 1'},
          {name: 'Sub entry 2'}
        ]
      }
    ]
  };
  
  /**
   * Hide all submenus except the specified one and any of its ancestor submenus
   */
  var hide_submenus = function(except){
    var submenus = document.getElementsByClassName('submenu');
    var excepts = [];
    var element = except;
    while (element.parentElement.tagName != 'NAV'){
      if (element.classList.contains('submenu'))
        excepts.push(element);
      element = element.parentElement;
    } 
    for (var i=0; i<submenus.length; i++){
      var hide = true;
      for (var j=0; j<excepts.length; j++){
        if (submenus[i] == excepts[j]){
          hide = false
          break;
        }
      }
       
      // hide the submenus
      if (hide)
        submenus[i].classList.add('hidden');
    }
  }
  
  /**
   * Deactivate all menu items except the specified one and its direct ancestor menu items.
   */
  var deactivate_items = function(except){
    // get the ancestor-and-self  menuitems
    var excepts = [];
    while(except.parentElement.tagName != 'NAV'){
      if (except.classList.contains('menuitem'))
        excepts.push(except);
      except = except.parentElement;
    }
    
    // get all menuitems and deactivate them except for the excepts
    var menuitems = document.getElementsByClassName('menuitem');
    for (var i=0; i<menuitems.length; i++){
      var hide = true;
      for (var j=0; j<excepts.length; j++){
        if (menuitems[i] == excepts[j]){
          hide = false;
          break;
        }
      }
      
      // deactivate
      if (hide)
        menuitems[i].classList.remove('active');
    }
  }
  
  /**
   * Click event for a leaf in the menu, just popup a message.
   */
  var leafclick = function(e){
    hide_submenus(this.parentElement);
    deactivate_items(this);
    e.stopPropagation();
    alert('Selected "' + this.textContent + '"');
  };
  
  /**
   * Click event for a menu item with a submenu
   */
  var submenuclick = function(e){
    hide_submenus(this.parentElement);
    deactivate_items(this);
    var childmenu = this.getElementsByClassName('submenu')[0];
    this.classList.add('active');
    childmenu.classList.remove('hidden');
    e.stopPropagation();
  };
  
  /**
   * Recursively parse the menu data which we assume is of the form above, and translate it into a set of nested divs that mimic 
   * the recursive structure of the data.
   * 
   * @param menu_obj: Simple object with structure of above
   * @return: DOM div element containing the nested structure represented by menu_obj
   */
  var parse_menu = function(menu_obj){
    var parent = document.createElement('div');
    var children = []; // @TODO do I need this?
    
    // no name field indicates top level menu
    if (menu_obj.name)
      parent.classList.add('submenu');
    else
      parent.classList.add('topmenu');
    
    // process the children items
    if (menu_obj.items && menu_obj.items.length > 0){
      for (var i=0; i<menu_obj.items.length; i++){
        var child = document.createElement('div');
        child.textContent = menu_obj.items[i].name;
        child.classList.add('menuitem');
        
        // if compound menu item, recursively process it; otherwise indicate it is a leaf
        if (menu_obj.items[i].items){
          var arrow = document.createElement('div');
          arrow.classList.add('arrow');
          child.appendChild(arrow);
          var submenu = parse_menu(menu_obj.items[i]);
          submenu.classList.add('hidden');
          child.appendChild(submenu);
          child.onclick = submenuclick;
        }
        else{
          child.classList.add('leaf');
          child.onclick = leafclick;
        }
        
        // add menu item entry to parent
        parent.appendChild(child);
      }
    }
    
    return parent;
  };
  
  // make sure body is loaded before adding nodes to the dom
  document.body.onload = function(){
    menu_dom = parse_menu(the_menu);
    document.body.getElementsByTagName('nav')[0].appendChild(menu_dom);
  };
})();