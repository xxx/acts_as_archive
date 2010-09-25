module ActsAsArchive
  module Base
    module Destroy

      def self.included(base)
        unless base.included_modules.include?(InstanceMethods)
          base.class_eval do
            alias_method :delete!, :delete
            
            class << self
              alias_method :delete_all!, :delete_all
            end
            
            before_destroy Proc.new { |r|
              unless r.new_record?
                r.class.copy_to_archive("#{r.class.primary_key} = #{r.id}", false, false)
              end
            }
      
          end
          
          base.send :include, InstanceMethods
          base.send :extend, ClassMethods
        end
      end

      module ClassMethods
        def copy_to_archive(conditions, import = false, delete = true)
          where = sanitize_sql(conditions)
          where = "WHERE #{where}" unless where.blank?
          insert_cols = column_names.clone
          select_cols = column_names.clone
          if insert_cols.include?('deleted_at')
            unless import
              select_cols[select_cols.index('deleted_at')] = "'#{Time.now.utc.to_s(:db)}'"
            end
          else
            insert_cols << 'deleted_at'
            select_cols << "'#{Time.now.utc.to_s(:db)}'"
          end

          insert_cols.map! { |col| connection.quote_column_name(col) }
          select_cols.map! { |col| col =~ /^\'/ ? col : connection.quote_column_name(col) }

          connection.execute(%{
            INSERT INTO archived_#{table_name} (#{insert_cols.join(', ')})
              SELECT #{select_cols.join(', ')}
              FROM #{table_name}
              #{where}
          })
          connection.execute("DELETE FROM #{table_name} #{where}") if delete
        end
      
        def delete_all(conditions=nil)
          copy_to_archive(conditions)
        end
      end

      module InstanceMethods
        def delete
          unless new_record?
            self.class.copy_to_archive("#{self.class.primary_key} = #{id}")
          end
          @destroyed = true
          freeze
        end
        
        def destroy!
          transaction { delete! }
        end
      end
    end
  end
end
