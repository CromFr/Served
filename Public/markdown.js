function markdownize(){

    var md_converter = new Showdown.converter();

    // Convert each markdown classes to html
    $( ".markdown" ).each(function( index ) {
        var content = $(this).text();
        content = md_
        converter.makeHtml(content);
        $(this).text(content);
    });

}
