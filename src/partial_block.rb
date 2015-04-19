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

  def matches(*argumentos)
    if coincide_aridad_entre_argumentos_y_parametros?(@lista_tipos_parametros,argumentos)
      matchea = @lista_tipos_parametros.zip(argumentos).all? { |tipo_parametro, argumento| argumento.is_a? tipo_parametro }
    end

    matchea || false
  end

  def coincide_aridad_entre_argumentos_y_parametros?(lista_tipos_parametros, argumentos)
    lista_tipos_parametros.size==argumentos.size
  end

end