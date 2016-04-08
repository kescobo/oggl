using DataFrames, DataArrays
using Gadfly

df = readtable("../data/toy_data.csv")

fmt = "yyyy-mm-ddHH:MM:SS"

df[:Client] = map(1:length(df[:Client])) do i
    if typeof(df[:Client][i]) == NAtype
        return "None"
    else
        return df[:Client][i]
    end
end

# creates new columns of `DateTime`s for `Start` and `End`
df[:Start] = map(1:length(df[:Start_time])) do i
    d = df[:Start_date][i]
    t = df[:Start_time][i]
    return DateTime(d*t, fmt)
end

df[:End] = map(1:length(df[:End_time])) do i
    d = df[:End_date][i]
    t = df[:End_time][i]
    return DateTime(d*t, fmt)
end

df[:Elapsed] = map(1:length(df[:End_time])) do i
    s = df[:Start][i]
    e = df[:End][i]
    return e - s
end

df[:Day] = [Dates.dayname(d) for d in df[:Start]]

# replace empty descriptions with NA
# df[df[:Description] .== "", :Description] = NA
# make columns into factors
pool!(df, [:Client, :Project, :Description, :Day])

clients = levels(df[:Client])
projects = levels(df[:Project])
descriptions = levels(df[:Description])
days = levels(df[:Day])

tuesdays = df[Dates.dayname(df[:Start]) .== "Tuesday", [:Project, :Client, :Elapsed]]
by(tuesdays, :Project, e -> int(sum(e[:Elapsed])) / 3600000)

df2 = df[:, [:Start, :Day, :Client, :Project, :Elapsed]]
sort!(df2, cols = [order(:Start, by = Dates.dayofweek)])

by(df2, :Client) do f
    sum(f[:Elapsed])
end

by(df2, [:Day, :Client], e -> int(sum(e[:Elapsed])) / 3600000)

byday = groupby(df2, [:Day, :Client])
byday

c = plot(by(df2, :Client, e -> int(sum(e[:Elapsed])) / 3600000)[2:7, :], x = "Client", y = "x1", Geom.bar, Guide.YLabel("Hours"))
d = plot(by(df2, :Day, e -> int(sum(e[:Elapsed])) / 3600000), x = "Day", y = "x1", Geom.bar, Guide.YLabel("Hours"))
cd = plot(by(df2, [:Day, :Client], e -> int(sum(e[:Elapsed])) / 3600000),
     x = "Day", y = "x1", color = "Client", Geom.bar, Coord.Cartesian(ymax = 45), Guide.YLabel("Hours"))


draw(PNG("../data/clients.png", 12cm, 12cm), c)
draw(PNG("../data/days.png", 12cm, 9cm), d)
draw(PNG("../data/clients-by-day.png", 12cm, 14cm), cd)
