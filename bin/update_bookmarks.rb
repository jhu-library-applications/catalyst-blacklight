# Update bookmarks table document_type column to 'SolrDocument', needed
# for our upgrade to Blacklight 4.5+
#
#
# Is 'idempotent' for now -- if there have been old Blacklight's running against
# db, may need to run again. 

Bookmark.connection.execute("UPDATE bookmarks SET document_type='SolrDocument' WHERE document_type is NULL")