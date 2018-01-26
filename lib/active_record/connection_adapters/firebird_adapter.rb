require 'fb'

require 'active_record/connection_adapters/firebird/connection'
require 'active_record/connection_adapters/firebird/database_limits'
require 'active_record/connection_adapters/firebird/database_statements'
require 'active_record/connection_adapters/firebird/quoting'
require 'active_record/connection_adapters/firebird/schema_statements'
require 'active_record/connection_adapters/firebird/table_definition'

require 'arel/visitors/firebird'

class ActiveRecord::ConnectionAdapters::FirebirdAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter

  ADAPTER_NAME = "Firebird".freeze

  include ActiveRecord::ConnectionAdapters::Firebird::DatabaseLimits
  include ActiveRecord::ConnectionAdapters::Firebird::DatabaseStatements
  include ActiveRecord::ConnectionAdapters::Firebird::Quoting
  include ActiveRecord::ConnectionAdapters::Firebird::SchemaStatements

  @@default_transaction_isolation = :read_committed
  cattr_accessor :default_transaction_isolation

  def arel_visitor
    @arel_visitor ||= Arel::Visitors::Firebird.new(self)
  end

  def prefetch_primary_key?(table_name = nil)
    true
  end

  def active?
    return false unless @connection.open?

    @connection.query("SELECT 1 FROM RDB$DATABASE")
    true
  rescue
    false
  end

  def reconnect!
    disconnect!
    @connection = ::Fb::Database.connect(@config)
  end

  def disconnect!
    super
    @connection.close rescue nil
  end

  def reset!
    reconnect!
  end

protected

  def translate_exception(e, message)
    case e.message
    when /violation of FOREIGN KEY constraint/
      InvalidForeignKey.new(message, e)
    when /violation of PRIMARY or UNIQUE KEY constraint/, /attempt to store duplicate value/
      RecordNotUnique.new(message, e)
    when /This operation is not defined for system tables/
      ActiveRecordError.new(message)
    else
      super
    end
  end

end
