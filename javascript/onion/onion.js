const decodeAscii85 = (str) => {
    let strProcessed = str.replace(/^<~/, '')
    strProcessed = strProcessed.replace(/\s+/, '');

    let seek = 0;
    let word = str.substring(seek, seek + 5);

    while (word !== '') {
        console.log(word.split(''));
        // put the algorithm here check for padding with up to 5 'u' characters on the last word

        seek += 5;
        word = str.substring(seek, seek + 5);
    }
};
const input = "<~4[!!l9OW3XEZd(i2*)jHBlnQ5F(HIiE+O&uFD5Z2F!+aO4Ztqk4Ztqk4Zt";
const result = decodeAscii85(input);
