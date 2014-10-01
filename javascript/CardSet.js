/**
 * This module represents a set of flashcard objects/views/etc. The set of cards is implemented as a
 * scrollable view and is specified by the given SU input parameter.
 * 
 * @param stuID: (integer) the stuID of the SU to build a set of flashcards for; this simply gets passed to
 *               CardDataSet module.
 * @param stuNumber: (integer) the numerical study unit number, used in card display
 * @return: (ScrollableView) each view in the ScrollableView is a single card implemented as a WebView.
 */
function CardSet(stuID,stuNumber){
   //load component dependencies
   var CardDataSet = require('data/CardDataSet');
   var Globals = require('Globals');
   var Utils = require('ui/common/Utils');
   
   var osname = Globals.get('osname');
   
   // to work around iOS bug where the webview which displays each card gets its height messed up when its height is specified as a percent,
   // we need to instead use actual pixels for the height, which of course depends on the orientation and the specific device
   if (!Globals.exists('cardsetPortHeight')){
      // set the portrait and landscape heights we will need based on the screen portrait and landscape heights; NOTE this
      // logic assumes knowledge of the percent heights of the other views that comprise the Cards window (CardsWin.js)
            
      // scale factor: the percentage of the surrounding area that the webview should take up
      var scaleFactor = 0.9;       // in landscape, we hide the banners so the webview gets 90% of full screen height 

      Globals.set('cardsetPortHeight',Math.round((Globals.get('windowPortHeight') - Utils.deviceRelativeHeightPX(0.2)) * scaleFactor));
      Globals.set('cardsetLandHeight',Math.round(Globals.get('windowLandHeight') * scaleFactor));
   }
   
   // this adds the given view to a plain view that acts as a background
   // (we needed this to workaround crazy Android behavior where the child
   // view of the ScrollableView was taking up the full space no matter what
   // dimensions of the child are)
   var bgView = osname == 'android' ? 
      function (view){
         var bg = Titanium.UI.createView({backgroundColor: '#555555'});
         bg.add(view);
         return bg;
       } :
       function (view){return view;};
   
   // android changed behavior in Titanium 3.0.2 and you now have to specify the baseURL for local content    
   var setTheHTML = osname == 'android' ?
      function (wv,html){ wv.setHtml(html,{ baseURL: 'file:///android_asset/Resources/' }); } :
      function (wv,html){ wv.setHtml(html); }; 
   
   // the ScrollableView
   var self = Titanium.UI.createScrollableView({
      showPagingControl:false,
      currentPage:0,
      backgroundColor:'#555555',
      height: Utils.fillRelativeHeightPX(0.8)
   });
   
   // retrieve the card data set
   var aCards = new CardDataSet(stuID,stuNumber);
   
   // initialize the ScrollableView (need the extra check because Ti.Gesture.isPortrait() is not trustworthy if iPhone is FACE_UP/FACE_DOWM)
   var webviewHeight = (Ti.Gesture.isPortrait() || (Ti.Platform.displayCaps.platformHeight > Ti.Platform.displayCaps.platformWidth)) ? 
                       Globals.get('cardsetPortHeight') :
                       Globals.get('cardsetLandHeight');
 
   // iOS has a problem with the webviews in the scrollableview properly displaying their content; it seems to be the same sort of issues as I have tackled
   // in CardsWin.js with orientation changes, where we need to fire off a reload() to get the webview to work right. This seems to only happen on initial loading,
   // and actually only on the first running of the app after starting Titanium (super weird); so this seems to be the least intrusive and functional fix:
   // on a postlayout event (which gets fired when the scrollableview starts bringing the webview into its cluster of 3 current views), cause a reload, then remove
   // itself as a listener so it only happens once.
   var fixWebView = function(e){
      if (e.source == this){
         this.removeEventListener('postlayout',fixWebView);
         this.reload();
      }
   };

   for (var i=0, numCards=aCards.length; i<numCards; i++){
      var webview = Ti.UI.createWebView({
         html: '<html><body>placeholder</body></html>',
         top: '5%',
         left: '5%',
         right: '5%',
         height: (osname == 'android' ? '90%' : webviewHeight),
         scalesPageToFit: false,
         backgroundColor: '#555555',
         willHandleTouches: false
      });
      setTheHTML(webview,aCards[i].front);
      // iOS has strange problem with webviews in scrollableview that is fixed by this event listener, but due to other iOS bug workarounds, we only do
      // this for the non-first-3 webviews; this is because the scrollableview preloads the first 3 webviews, and they are in a different situation
      if (osname != 'android'){
         if (i > 2){
            webview.addEventListener('postlayout',fixWebView);
         }
      }
      // iOS has more strange problems: seems I can't remove then add the same event listener for views after the first 3, but if you add some extra
      // empty event listener for the same event (load), it then seems to work
      if (osname != 'android'){
         webview.addEventListener('load',function(e){});
      }
      self.addView(bgView(webview));
   }
   
   // --- HELPER FUNCTIONS ---
   
   // get ith (0-based) webview; the trickery is related to how bgview() function above sets up the webviews as a workaround for silliness
   var getTheWebView = osname == 'android' ?
      function(i){ return self.views[i].children[0]; } :
      function(i){ return self.views[i]; };

   // webview based on self.currentPage
   var getCurrentWebView = function(){
      return getTheWebView(self.currentPage);
   };
   
   // --- EXPORTED CUSTOM FUNCTIONS ---
   var selfHelper = {};
   
   // wrapper for gettheWebView() that checks for the array boundary and returns appropriate views
   selfHelper.getWebView = function(i){
      if (i < 0) return getTheWebView(0);
      if (i >= self.views.length) return getTheWebView(self.views.length - 1);
      return getTheWebView(i);
   };
   
   // --- EVENTS ---

   // application-level cardclick event (sent from the webview local JS for a given card): flip the current card
   function flip(e){
      var currCard = aCards[self.currentPage];
      currCard.flip();
      var currView = getCurrentWebView();
      setTheHTML(currView,currCard.currentHTML());
   }
   Ti.App.addEventListener('app:cardclick',flip);
   
   // webview load: fix the font for a reloaded webview to be what the user had chosen previously for this card; this is only assigned to
   // webviews where the user changed the font
   function fontReload(e){
      
      // the different platforms end up reloading the webviews at different times, so we have to generically figure out which webview we are
      // dealing with, and relate it to the corresponding Card object, which holds the current font size state; ideally we would just hold the
      // state of the font size in the webview object itself (e.g. as a custom attribute) but Titanium recommmends not doing that.
      
      // tell the webview (the current e.source firing the load event) to reload its font size
      var reloadIt = function(size){
         e.source.evalJS("fontsize('" + size + "')");
      }
      
      // most often the webview being reloaded is the current page of the scrollableview
      if (e.source == getCurrentWebView()){
         reloadIt(aCards[self.currentPage].getFontSize());
         return;
      }
      
      // second-most often is iOS where it could be anywhere within the range of 2 to the left up to 2 to the right
      for (var i = self.currentPage - 2, maxIndex = self.views.length - 1; i <= self.currentPage + 2; i++){
         if (i < 0 || i > maxIndex || i == self.currentPage) continue;
         if (e.source == getTheWebView(i)){
            reloadIt(aCards[i].getFontSize());
            return;
         }
      }
      
      // if here, then we did not find the webview that is reloading itself yet in any of the above common cases, so now do full scan of the webviews
      for (var i = 0, maxIndex = self.views.length - 1; i <= maxIndex; i++){
         if (e.source == getTheWebView(i)){
            reloadIt(aCards[i].getFontSize());
            return;
         }
      }
   }
   
   // application-level font size change event (sent from the webview local JS when the font is changed): record the new font size for later use
   function fontsize(e){
      aCards[self.currentPage].setFontSize(e.size);
      var currWebView = getCurrentWebView();
      currWebView.removeEventListener('load',fontReload);
      currWebView.addEventListener('load',fontReload);
   }
   Ti.App.addEventListener('app:fontsize',fontsize);
   
   // closing custom event: the parent window tells this ScrollableView to fire the 'closing' event when it is closing,
   // and in turn this ScrollableView takes care of any leakable cleanup such as removing the App-level listeners
   self.addEventListener('app:closing',function(e){
      Ti.App.removeEventListener('app:cardclick',flip);
      Ti.App.removeEventListener('app:fontsize',fontsize);
   });

   // return composite object consisting of the Ti.UI.ScrollableView and a helper object with related methods
   return {cardSetView: self, cardSetHelper: selfHelper};
}

module.exports = CardSet;