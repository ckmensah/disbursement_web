class TransMaster < ActiveRecord::Base
  def self.generate_trans_id
    sql = "select nextval('trans_master_seq')"
    val = ActiveRecord::Base.connection.execute(sql)
    val = val.values[0][0]

    "TRX#{val}"

  end

end
