defmodule Game.DataMuse.Words do
  def clues(word, count \\ 1) do
    word
    |> ml()
    |> Stream.filter(fn
      %{"tags" => tags} ->
        Enum.member?(tags, "n")

      _ ->
        true
    end)
    |> Stream.map(&Map.get(&1, "word"))
    |> Enum.map(&String.upcase/1)
    |> Stream.reject(&String.contains?(&1, " "))
    |> Stream.reject(&(String.contains?(word, &1) or String.contains?(&1, word)))
    |> Stream.reject(&(String.jaro_distance(&1, word) >= 0.75))
    |> Stream.take(10)
    |> Enum.shuffle()
    |> Enum.take(count)
  end

  def guess(words) do
    words
    |> Enum.join(",")
    |> ml()
    |> Stream.filter(fn
      %{"tags" => tags} ->
        Enum.member?(tags, "n")

      _ ->
        true
    end)
    |> Stream.map(&Map.get(&1, "word"))
    |> Enum.map(&String.upcase/1)
    |> Stream.reject(&String.contains?(&1, " "))
    |> Stream.reject(fn suggestion ->
      Enum.reduce(words, false, fn word, rejected? ->
        rejected? or String.contains?(word, suggestion) or String.contains?(suggestion, word)
      end)
    end)
    |> Enum.reject(fn suggestion ->
      Enum.reduce(words, false, fn word, rejected? ->
        rejected? or String.jaro_distance(word, suggestion) >= 0.75
      end)
    end)
    |> hd()
  end

  def ml(input) do
    "md=p&ml=#{input}"
    |> call()
  end

  def rel_jja(input) do
    call("rel_jja=#{input}")
  end

  def rel_jjb(input) do
    call("rel_jjb=#{input}")
  end

  def rel_syn(input) do
    call("rel_syn=#{input}")
  end

  def rel_trg(input) do
    call("rel_trg=#{input}")
  end

  def call(qs) do
    {:ok, {_, _, raw}} = :httpc.request('https://api.datamuse.com/words?#{qs}')

    Jason.decode!(raw)
  end
end
