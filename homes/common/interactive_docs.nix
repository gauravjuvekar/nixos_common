{ pkgs, ... }:
{
  home.packages = with pkgs; [
    imagemagick
    pandoc
    pdftk
    poppler-utils # pdftotext
    qpdf
  ];
}
