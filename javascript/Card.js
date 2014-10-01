/**
 * This module is the logical model for a single flashcard. It contains front and
 * back content (HTML), and a state representation of whether the front or back
 * is "current" (meaning visible to the user).
 * 
 * @param cardData: object having 'front' and 'back' fields which contain the data
 *                  for the front and back of the card, respectively, along with a
 *                  unique ID for the card. Currently this module expects both
 *                  'front' and 'back' to be strings of HTML. 'id' currently is an
 *                  integer.
 * @return: (Card) this Card object.
 */

function Card(cardData){
   // --- MODULE CONSTANTS ---
   Card.prototype.FONT_SMALL  = 'small';
   Card.prototype.FONT_MEDIUM = 'medium';
   Card.prototype.FONT_LARGE  = 'large';
   Card.prototype.FRONT_SIDE  = 1
   Card.prototype.BACK_SIDE   = 2

   // --- FIELDS ---
   this.front = cardData.front; // the content of front of the card
   this.back = cardData.back;   // the content of back of the card
   this.current = this.FRONT_SIDE; // which side of the card is currently being displayed (start out with front showing)
   this.id = cardData.id;
   this.fontSizeFront = this.FONT_MEDIUM;   // the current font size for the front of the card (one of 'small', 'medium', 'large')
   this.fontSizeBack  = this.FONT_MEDIUM;   // the current font size for the back of the card (one of 'small', 'medium', 'large')
   
   // --- METHODS ---
   
   // Alternate (flip) the contents of the Card between front and back values
   Card.prototype.flip = function(){
      if (this.current == this.FRONT_SIDE)
         this.current = this.BACK_SIDE;
      else
         this.current = this.FRONT_SIDE;
   };
   
   // return the contents of the current face-up/visible side of the card
   Card.prototype.currentHTML = function(){
      return (this.current == this.FRONT_SIDE) ? this.front : this.back;
   };
   
   // set the current font size of the current side of the card to the given value if the value is one of the proper size values, otherwise no change
   Card.prototype.setFontSize = function(size){
      size = size.toLowerCase();
      if (size == this.FONT_SMALL || size == this.FONT_MEDIUM || size == this.FONT_LARGE){
         if (this.current == this.FRONT_SIDE)
            this.fontSizeFront = size;
         else
            this.fontSizeBack = size;
      }
   }
   
   // get the current font size of the current side of the card
   Card.prototype.getFontSize = function(){
      if (this.current == this.FRONT_SIDE)
         return this.fontSizeFront;
      else
         return this.fontSizeBack;
   }
}

module.exports = Card;
