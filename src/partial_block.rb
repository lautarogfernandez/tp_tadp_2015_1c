class PartialBlock

  attr_accessor :lista_tipos_parametros, :bloque

  def initialize (lista_tipos_parametros,&bloque)
    if(lista_tipos_parametros.size==bloque.arity)
      @lista_tipos_parametros=lista_tipos_parametros
      @bloque=bloque
    else
      raise(ArgumentError)#como hacemos? hacemos nosotros una excepcion o le pasamos por parametro un titulo y mensaje
    end
  end

end