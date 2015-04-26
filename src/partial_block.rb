class PartialBlock

  attr_accessor :lista_tipos_parametros, :bloque

  def coincide_aridad_entre_argumentos_y_parametros?(lista_tipos_parametros, argumentos)
    lista_tipos_parametros.size==argumentos.size
  end

  def initialize (lista_tipos_parametros,&bloque)
    if(coincide_aridad_entre_argumentos_y_parametros?(lista_tipos_parametros, bloque.parameters))
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

  def call(*argumentos)
    if(self.matches(*argumentos))
      self.bloque.call(*argumentos)
    else
      raise(ArgumentError)#como hacemos? hacemos nosotros una excepcion o le pasamos por parametro un titulo y mensaje
    end
  end

  def call_with_binding(*argumentos, new_self)
    new_self.instance_exec *argumentos, &bloque
  end

end