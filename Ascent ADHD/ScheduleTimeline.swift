//
//  ScheduleTimeline.swift
//  Ascent ADHD
//
//  The absolute-positioned 24-hour schedule grid — events sit at their real start time, sized by
//  duration, with overlap column-packing. Tap an empty slot to create at :00/:30; tap an event to
//  edit. A live "now" line marks the current time on today. Ported from the Home timeline in MainApp.
//

import SwiftUI

private let hourRowHeight: CGFloat = 67.5
private let minuteScale: CGFloat = 1.125   // 60 min * 1.125 = 67.5

struct TimelineBlock: Identifiable {
    enum Kind { case app, external, todo }
    let id: String
    let task: String
    let notes: String
    let startMin: Int
    let durationMins: Int
    let color: Color
    let kind: Kind
    let entry: ScheduleEntry?   // present for .app blocks (for editing)
}

struct ScheduleTimeline: View {
    let blocks: [TimelineBlock]
    let isToday: Bool
    let onCreate: (Int, Int) -> Void          // hour, minute
    let onEdit: (ScheduleEntry) -> Void

    // Overlap column-packing (ported from entryLayouts).
    private var layout: [String: (col: Int, total: Int)] {
        let sorted = blocks.sorted { $0.startMin < $1.startMin }
        var clusters: [[TimelineBlock]] = []
        var current: [TimelineBlock] = []
        var clusterEnd = -1
        for b in sorted {
            let end = b.startMin + b.durationMins
            if current.isEmpty || b.startMin < clusterEnd {
                current.append(b); clusterEnd = max(clusterEnd, end)
            } else {
                clusters.append(current); current = [b]; clusterEnd = end
            }
        }
        if !current.isEmpty { clusters.append(current) }

        var map: [String: (Int, Int)] = [:]
        for cluster in clusters {
            var cols: [Int] = []   // end-min of the last event in each column
            for b in cluster {
                let end = b.startMin + b.durationMins
                var placed = false
                for i in cols.indices where cols[i] <= b.startMin {
                    cols[i] = end; map[b.id] = (i, 1); placed = true; break
                }
                if !placed { cols.append(end); map[b.id] = (cols.count - 1, 1) }
            }
            let total = cols.count
            for b in cluster { map[b.id] = (map[b.id]?.0 ?? 0, total) }
        }
        return map.mapValues { (col: $0.0, total: $0.1) }
    }

    var body: some View {
        GeometryReader { geo in
            let areaX: CGFloat = 81
            let areaW = max(geo.size.width - areaX - 4, 40)
            ZStack(alignment: .topLeading) {
                // Hour grid.
                ForEach(0..<24, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        Text(formatTimeLabel(hour, 0))
                            .font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.5))
                            .frame(width: 65, alignment: .trailing).padding(.top, 2)
                        Rectangle().fill(Color(white: 0.8).opacity(0.4)).frame(height: 1).padding(.leading, 16)
                    }
                    .offset(y: CGFloat(hour) * hourRowHeight)
                }

                // Tap layer for creating events on empty slots.
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { value in
                        let totalMin = max(0, min(Double(value.location.y / minuteScale), 24 * 60 - 1))
                        let hour = Int(totalMin) / 60
                        let minute = (Int(totalMin) % 60) < 30 ? 0 : 30
                        onCreate(hour, minute)
                    })

                // Event cards.
                ForEach(blocks) { block in
                    let lay = layout[block.id] ?? (col: 0, total: 1)
                    let w = areaW / CGFloat(lay.total)
                    let h = max(CGFloat(block.durationMins) * minuteScale, 38)
                    eventCard(block, height: h)
                        .frame(width: w - (lay.total > 1 ? 2 : 0), height: h)
                        .offset(x: areaX + w * CGFloat(lay.col), y: CGFloat(block.startMin) * minuteScale)
                }

                // Live "now" line.
                if isToday {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
                    let nowMin = CGFloat((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
                    HStack(spacing: 0) {
                        Circle().fill(RidgelineBlue).frame(width: 6, height: 6)
                        Rectangle().fill(RidgelineBlue.opacity(0.8)).frame(height: 2)
                    }
                    .padding(.leading, 78)
                    .offset(y: nowMin * minuteScale)
                }
            }
        }
        .frame(height: 24 * hourRowHeight)
    }

    private func eventCard(_ block: TimelineBlock, height: CGFloat) -> some View {
        let isWhiteish = block.color.argb == PureWhite.argb || block.color.argb == SoftYellow.argb
        let textColor: Color = (isWhiteish || block.kind == .external) ? PureBlack : PureWhite
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if block.kind == .external {
                    Image(systemName: "calendar").font(.system(size: 11)).foregroundColor(RidgelineBlue)
                } else if block.kind == .todo {
                    Image(systemName: "checklist").font(.system(size: 11)).foregroundColor(textColor)
                }
                Text(block.task)
                    .font(.system(size: block.durationMins <= 15 ? 12 : 14, weight: block.kind == .external ? .medium : .bold))
                    .foregroundColor(textColor).lineLimit(1)
            }
            if height > 48 && !block.notes.isEmpty {
                Text(block.notes).font(.system(size: 11)).foregroundColor(textColor.opacity(0.8)).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 14).fill(block.color))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(
            block.kind == .external ? RidgelineBlue.opacity(0.4) : Color(white: 0.8).opacity(0.6), lineWidth: 1))
        .padding(.horizontal, 4).padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { if let e = block.entry { onEdit(e) } }
    }
}
