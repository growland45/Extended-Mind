A program I wrote for my own use, to extend my mind into the computer. This is in the genre of Xim and Tomboy - note software with many added features.

What's distinct about it:

1 It organizes everything arpund topics or concepts, called 'items'
2 It ranks notes and eternal links in order of importance
3 It has many useful dataabase views, such as:
 * items to ponder
 * dynamic sites to frequent
 * sites and documents to peruse.
 * dated actions (calendar items), to-do items
4 It stores everything in a sqlite database.
5 Relationships between items have verbs, not mere links.
6 Optional use of Web proxy per link, to simplify using Tor/privoxy.
7 Designed for scalability. I've got thousands of notes in mine.

(The UI is different from most for this very reason. And of course there's a search function.)

Other (not unique) features:

1 Relates items to each other
2 Links to external sites and documents

It's written in Perl and Tk. I may rewrite in Python some day. I just started in Perl and kept adding useful stuff as I felt a need.

Usage notes:

For safety, items, notes and relationships can't be deleted unless completely cleared first.

Relationship types have these classes:

A - action
M - membership
P - passive (nonaction, not membership)

![Screenshot](/screenshots/action.screenshot.jpg?raw=true)
![Screenshot](/screenshots/edit.scanned.site.screenshot.jpg?raw=true)
![Screenshot](/screenshots/item.main.screenshot.jpg?raw=true)
![Screenshot](/screenshots/item.notes.screenshot.jpg?raw=true)
![Screenshot](/screenshots/peruses.screenshot.jpg?raw=true)
![Screenshot](/screenshots/ponder.screenshot.jpg?raw=true)
![Screenshot](/screenshots/relate.screenshot.jpg?raw=true)
![Screenshot](/screenshots/scanned.site.screenshot.jpg?raw=true)
