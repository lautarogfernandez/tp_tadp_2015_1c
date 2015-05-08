class Object
  def distancia_parametro_parcial(tipo_parametro)
    self.class.ancestors.index(tipo_parametro)
  end
end

class PartialBlock

  attr_accessor :lista_tipos_parametros, :bloque

  def coincide_aridad_entre_argumentos_y_parametros?( argumentos)
    self.lista_tipos_parametros.size==argumentos.size
  end

  def initialize (lista_tipos_parametros,&bloque)
    @lista_tipos_parametros=lista_tipos_parametros
    if(self.coincide_aridad_entre_argumentos_y_parametros?(bloque.parameters))
      @bloque=bloque
    else
      raise ArgumentError, "No coincide la aridad del bloque con la cantidad de parametros"
    end
  end

  def matches(*argumentos)
    if self.coincide_aridad_entre_argumentos_y_parametros?(argumentos)
      matchea = self.lista_tipos_parametros.zip(argumentos).all? do |tipo_parametro, argumento|
        argumento.is_a? tipo_parametro
      end
    end
    matchea || false
  end

  def matches_tipos(lista_tipos)
    if self.coincide_aridad_entre_argumentos_y_parametros?(lista_tipos)
      matchea =  self.lista_tipos_parametros.zip(lista_tipos).all? do |tipo_parametro, tipo|
        tipo.ancestors.include?(tipo_parametro)
      end
    end
    matchea || false
  end


  def call(*argumentos)
    if(self.matches(*argumentos))
      self.bloque.call(*argumentos)
    else
      raise ArgumentError, "Los argumentos no coincide con el tipo requerido por el bloque"
    end
  end

  def call_with_binding(*argumentos, new_self)
    # no me gusta de usar call_with_binding que abre la posibilidad de ejecutar el partial block sin el mathchs.
    # El tema uqe para solucionarlo habria que usar el matches adentro dle nuevo call_with_binding (llamandose 2 veces al matches)

    new_self.instance_exec *argumentos, &bloque
  end

  def distancia_parametro_total(argumentos)
    self.lista_tipos_parametros.collect { |tipo_parametro| argumentos[self.lista_tipos_parametros.index(tipo_parametro)].distancia_parametro_parcial(tipo_parametro) * (self.lista_tipos_parametros.index(tipo_parametro)+1) }.reduce(0, :+)
  end

end