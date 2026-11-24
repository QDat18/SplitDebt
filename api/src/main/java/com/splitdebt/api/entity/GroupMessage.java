package com.splitdebt.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "group_messages",
        indexes = {
                @Index(name = "idx_group_messages_group_id_id", columnList = "group_id, id")
        },
        uniqueConstraints = {
                @UniqueConstraint(name = "uq_sender_client_message_id", columnNames = {"sender_id", "client_message_id"})
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupMessage extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private Group group;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "client_message_id", nullable = false, length = 36)
    private String clientMessageId;
}
