

sub init()
  m.top.id = "markupgriditem"
  m.itemposter = m.top.findNode("itemPoster")
  m.itemmask = m.top.findNode("itemMask")
  m.itemtext = m.top.findNode("itemtext")
end sub

function itemContentChanged()
  ' "if or when content of an item changes do this":
  itemData = m.top.itemContent
  m.itemImage.uri = itemdata.HDPOSTERURL
  m.itemText.text = itemData.text
end function

sub showcontent()
  ' "when content is added to grid, do this for each item in grid:"
  itemcontent = m.top.itemContent
  ?"itemcontent=" itemcontent
  m.itemposter.uri = itemcontent.HDPOSTERURL
  m.itemtext.text=itemcontent.text
end sub
