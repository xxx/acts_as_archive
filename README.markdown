ActsAsArchive
=============

Don't delete your records, move them to a different table.

Like `acts_as_paranoid`, but doesn't mess with your SQL queries.

Requirements
------------

This gem is intended to work with ActiveRecord version 3.0.0 and later.

Install
-------

**Gemfile**:

    gem 'acts_as_archive', :git => 'http://github.com/xxx/acts_as_archive.git'

Update models
-------------

Add `acts_as_archive` to your models:

    class Article < ActiveRecord::Base
      acts_as_archive
    end

<a name="create_archive_tables"></a>

Create archive tables
---------------------

Add this line to a migration:

`ActsAsArchive.update Article, Comment`

Replace `Article, Comment` with your own models that use `acts_as_archive`

Archive tables mirror your table's structure, but with an additional `deleted_at` column.

There is an [alternate way to create archive tables](http://wiki.github.com/winton/acts_as_archive/alternatives-to-migrations) if you don't like migrations.

That's it!
----------

Use `destroy`, `delete`, and `delete_all` like you normally would.

Records move into the archive table instead of being destroyed.

What if my schema changes?
--------------------------

New migrations are automatically applied to the archive table.

No action is necessary on your part.

Query the archive
-----------------

Add `::Archive` to your ActiveRecord class:

    Article::Archive.find(:first)

Restore from the archive
------------------------

Use `restore_all` to copy archived records back to your table:

    Article.restore_all([ 'id = ?', 1 ])

Auto-migrate from acts\_as\_paranoid
------------------------------------

If you previously used `acts_as_paranoid`, the `ActsAsArchive.update`
call will automatically move your deleted records to the archive table
(see <a href="#create_archive_tables">_Create archive tables_</a>).

Original `deleted_at` values are preserved.

Add indexes to the archive table
--------------------------------

To keep insertions fast, there are no indexes on your archive table by default.

If you are querying your archive a lot, you will want to add indexes:

    class Article < ActiveRecord::Base
      acts_as_archive :indexes => [ :id, :created_at, :deleted_at ]
    end

Call `ActsAsArchive.update` upon adding new indexes
(see <a href="#create_archive_tables">_Create archive tables_</a>).

Delete records without archiving
--------------------------------

To destroy a record without archiving:

    article.destroy!

To delete multiple records without archiving:

    Article.delete_all!(["id in (?)", [1,2,3]])
