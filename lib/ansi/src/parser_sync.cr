module Ansi
  @@parser_pool = [] of Parser
  @@parser_pool_mutex = Mutex.new

  # ameba:disable Naming/AccessorMethodName
  def self.get_parser : Parser
    @@parser_pool_mutex.synchronize do
      parser = @@parser_pool.pop?
      return parser if parser
    end

    parser = Parser.new
    parser.set_params_size(ParserTransition::MaxParamsSize)
    parser.set_data_size(1024 * 4)
    parser
  end

  def self.put_parser(p : Parser)
    p.reset
    p.data_len = 0
    @@parser_pool_mutex.synchronize do
      @@parser_pool << p
    end
  end
end
